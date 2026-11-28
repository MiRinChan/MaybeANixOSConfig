{
  config,
  lib,
  pkgs,
  repoRoot,
  ...
}: let
  # Place CLI-launched Throne instances into app.slice/app-throne-cli-*.service so
  # both nftables (@throne_cgroups) and nohang Tier 0 match Throne/ThroneCore
  # regardless of whether Throne was started from KDE Launcher or a terminal.
  throneLauncher = lib.hiPrio (pkgs.writeShellScriptBin "Throne" ''
    for arg in "$@"; do
      case "$arg" in
        -h|--help|-v|--version|--print-connection)
          exec ${config.programs.throne.package}/bin/Throne "$@"
          ;;
      esac
    done
    uid=$(${pkgs.coreutils}/bin/id -u)
    if [ "''${THRONE_IN_UNIT:-}" != 1 ] \
      && ! ${pkgs.gnugrep}/bin/grep -Eq '/app-[Tt]hrone(@|-)' /proc/self/cgroup 2>/dev/null \
      && [ -S "/run/user/$uid/bus" ]; then
      exec ${pkgs.systemd}/bin/systemd-run --user --quiet --collect --same-dir \
        --setenv=THRONE_IN_UNIT=1 \
        --property=Slice=app.slice \
        --unit="app-throne-cli-$$" \
        ${config.programs.throne.package}/bin/Throne "$@"
    fi
    exec ${config.programs.throne.package}/bin/Throne "$@"
  '');
  ntpWifiRoutes = pkgs.writeShellScript "ntp-wifi-routes" ''
    set -euo pipefail
    exec 9>/run/lock/ntp-wifi-routes.lock
    ${pkgs.util-linux}/bin/flock 9
    ip=${pkgs.iproute2}/bin/ip
    for family in -4 -6; do
      "$ip" "$family" route replace unreachable default table 123 metric 42760
      "$ip" "$family" route flush table 123 dev wlp0s20f3
      routes=$("$ip" "$family" route show table main dev wlp0s20f3 2>/dev/null || true)
      # Copy connected routes before their default gateway.
      for kind in connected default; do
        while read -r -a route; do
          [ "''${#route[@]}" -gt 0 ] || continue
          if [ "''${route[0]}" = default ]; then
            [ "$kind" = default ] || continue
          else
            [ "$kind" = connected ] || continue
          fi
          "$ip" "$family" route replace table 123 "''${route[@]}" dev wlp0s20f3
        done <<< "$routes"
      done
      while "$ip" "$family" rule del pref 5101 ipproto udp dport 123 table 123 2>/dev/null; do :; done
      "$ip" "$family" rule add pref 5101 ipproto udp dport 123 table 123
    done
  '';
in {
  # NTP clients use Wi-Fi. Table 123 rejects traffic while Wi-Fi has no route.
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "ntp-wifi-dispatcher" ''
        [ "''${1:-}" = wlp0s20f3 ] || exit 0
        ${ntpWifiRoutes}
      '';
    }
  ];
  systemd.services.ntp-wifi-direct = {
    description = "Route NTP clients through Wi-Fi";
    after = ["network.target" "nftables.service"];
    before = ["chronyd.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.iproute2];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = "${ntpWifiRoutes}";
    preStop = ''
      for family in -4 -6; do
        while ip "$family" rule del pref 5101 ipproto udp dport 123 table 123 2>/dev/null; do :; done
        ip "$family" route flush table 123
      done
    '';
  };
  networking.nftables.tables.ntp_wifi_direct = {
    family = "inet";
    content = ''
      chain output {
        type route hook output priority mangle - 3; policy accept;
        udp dport 123 counter meta mark set 0x2024 ct mark set 0x2024
      }
    '';
  };
  systemd.services.chronyd = {
    requires = ["ntp-wifi-direct.service"];
    after = ["ntp-wifi-direct.service"];
  };
  programs.throne = {
    enable = true;
    tunMode.enable = true;
    # tunMode.setuid = true;
    # package = pkgs.stable.throne;
  };
  environment.systemPackages = [
    pkgs.thronectl
    throneLauncher
  ];

  services.tailscale = {
    enable = true;
    extraSetFlags = ["--operator=mirin"];
  };
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [config.services.tailscale.interfaceName];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [config.services.tailscale.port];
    # Exit routing can send unmarked discovery replies through tailscale0, and
    # physical NIC replies for ThroneCore/NTP/Win11 arrive with mark 0 while
    # table 52 routes public destinations to tailscale0.
    extraReversePathFilterRules = ''
      udp dport ${toString config.services.tailscale.port} accept
      iifname "wlp0s20f3" udp sport 123 ct state established,related ct direction reply accept
      iifname { "wlp0s20f3", "eno1" } ct state established,related ct direction reply ct mark { 0x00002024, 0x00004000 } accept
    '';
  };

  systemd.services.tailscaled.postStart = ''
    for i in $(${pkgs.coreutils}/bin/seq 1 30); do
      if ${pkgs.iptables}/bin/iptables -S ts-input >/dev/null 2>&1; then
        ${pkgs.iptables}/bin/iptables -C ts-input -i lo -s 100.64.0.0/10 -j ACCEPT 2>/dev/null || \
        ${pkgs.iptables}/bin/iptables -I ts-input 1 -i lo -s 100.64.0.0/10 -j ACCEPT || true
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.2
    done
    exit 0
  '';

  # Coexistence of Throne TUN, Tailscale exit node, and VM exit-only isolation
  # across all four states (neither on, Tailscale only, Throne only, both on):
  # - Leave Tailscale's table 52 rule (pref 5270) intact so unmarked `ip route get`
  #   queries (used by coding-vm/audit-vm startup and runtime guards) continue to
  #   observe tailscale0 when an exit node is active.
  # - Mark Throne/ThroneCore (@throne_cgroups) non-tailnet egress with 0x2025 and
  #   route 0x2025 via main (pref 5200/5201) + masquerade on physical NICs so
  #   proxy tunnels, URL tests, and subscription updates never loop into table 2022
  #   (even with auto_redirect off) and never get trapped in Tailscale table 52.
  # - Mark normal host egress with 0x2023 and route 0x2023 through pref 5202/5204/5205
  #   before table 52: DNS (dport 53) jumps straight to table 2022 (5202->5205),
  #   connected non-DNS LAN subnets stay in main (5204), and internet traffic enters
  #   Throne's table 2022 (5205) when throne-tun is up or falls through cleanly to
  #   table 52 (when Tailscale exit node is on) or main (when both are off).
  # - Mark tailnet peers (100.64.0.0/10, fd7a:115c:a1e0::/48), tailscaled sockets
  #   (0x80000), inbound tailscale0 connections, and coding-vm/audit-vm cgroups
  #   with 0x2024 so they always bypass Throne interception.
  # - Enforce a cgroupv2 kill-switch so coding-vm and audit-vm can only leave via
  #   lo (host SSH port-forward) or tailscale0, never throne-tun or physical NICs.
  # NixOS checks nftables rules inside LKL (`lklWithFirewall`), whose kernel lacks
  # `socket cgroupv2` support. Strip those lines in the sandbox check only; the
  # live ruleset keeps them intact and is validated on the host kernel.
  networking.nftables.preCheckRuleset = ''
    sed -i '/socket cgroupv2 level 5 @\(vm\|throne\)_cgroups/d' ruleset.conf
  '';
  networking.nftables.tables.ts-priority = {
    family = "inet";
    content = ''
      set vm_cgroups {
        type cgroupsv2
      }
      set throne_cgroups {
        type cgroupsv2
      }
      chain prerouting_pre {
        type filter hook prerouting priority mangle - 2; policy accept;
        iifname "${config.services.tailscale.interfaceName}" ct direction original counter ct mark set 0x00002024
      }
      chain output_pre {
        type route hook output priority mangle - 2; policy accept;
        socket cgroupv2 level 5 @vm_cgroups counter meta mark set 0x00002024 ct mark set 0x00002024 return
        meta skuid 0 meta mark & 0x00ff0000 == 0x00080000 counter ct mark set 0x00002024 return
        meta nfproto ipv4 ip daddr 100.64.0.0/10 meta mark set 0x00002024 ct mark set 0x00002024 return
        meta nfproto ipv6 ip6 daddr fd7a:115c:a1e0::/48 meta mark set 0x00002024 ct mark set 0x00002024 return
        oifname "lo" return
        fib daddr type local return
        meta mark 0x00002024 return
        meta nfproto ipv4 ip daddr { 127.0.0.0/8, 169.254.0.0/16, 224.0.0.0/4, 255.255.255.255/32 } return
        meta nfproto ipv6 ip6 daddr { ::1/128, fe80::/10, ff00::/8 } return
        meta mark 0x00002025 counter ct mark set 0x00002024 return
        socket cgroupv2 level 5 @throne_cgroups counter meta mark set 0x00002025 ct mark set 0x00002024
      }
      chain output_transport {
        type route hook output priority mangle + 3; policy accept;
        meta skuid 0 ct mark 0x00002024 meta mark & 0x00ff0000 != 0x00080000 udp sport ${toString config.services.tailscale.port} counter meta mark set 0x00080000
      }
      chain output_to_tun {
        type route hook output priority mangle + 4; policy accept;
        oifname "lo" return
        oifname "throne-tun" return
        fib daddr type local return
        meta mark 0x00002024 return
        meta mark 0x00002025 return
        ct mark 0x00002024 return
        meta mark 0x00002023 return
        meta mark & 0x00ff0000 == 0x00080000 return
        socket cgroupv2 level 5 @vm_cgroups return
        socket cgroupv2 level 5 @throne_cgroups return
        meta nfproto ipv4 ip daddr { 127.0.0.0/8, 169.254.0.0/16, 224.0.0.0/4, 255.255.255.255/32 } return
        meta nfproto ipv6 ip6 daddr { ::1/128, fe80::/10, ff00::/8 } return
        counter meta mark set 0x00002023
      }
      chain prerouting_to_tun {
        type filter hook prerouting priority mangle + 4; policy accept;
        iifname != { "virbr0", "docker0" } return
        fib daddr type local return
        meta mark 0x00002024 return
        meta mark 0x00002025 return
        ct mark 0x00002024 return
        meta mark 0x00002023 return
        meta nfproto ipv4 ip daddr { 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 224.0.0.0/4, 255.255.255.255/32 } return
        meta nfproto ipv6 ip6 daddr { ::1/128, fd7a:115c:a1e0::/48, fe80::/10, ff00::/8 } return
        counter meta mark set 0x00002023
      }
      chain vm_killswitch {
        type filter hook output priority filter; policy accept;
        socket cgroupv2 level 5 @vm_cgroups oifname != { "lo", "${config.services.tailscale.interfaceName}" } counter reject with icmpx admin-prohibited
      }
      chain postrouting_phys {
        type filter hook postrouting priority mangle; policy accept;
        oifname { "wlp0s20f3", "eno1" } ct direction original ct mark 0x00000000 counter ct mark set 0x00004000
      }
      chain postrouting_nat {
        type nat hook postrouting priority srcnat; policy accept;
        meta mark 0x00002025 oifname { "wlp0s20f3", "eno1" } masquerade
      }
    '';
  };
  systemd.services.throne-tailscale-rules = {
    description = "Policy routing rules for Throne TUN and Tailscale coexistence";
    after = ["network-pre.target"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.iproute2];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for family in -4 -6; do
        for pref in 5200 5201 5202 5204 5205; do
          while ip "$family" rule del pref "$pref" 2>/dev/null; do :; done
        done
        ip "$family" rule add pref 5200 fwmark 0x2025 lookup main
        ip "$family" rule add pref 5201 fwmark 0x2025 unreachable
        ip "$family" rule add pref 5202 fwmark 0x2023 dport 53 goto 5205
        ip "$family" rule add pref 5204 fwmark 0x2023 lookup main suppress_prefixlength 0
        ip "$family" rule add pref 5205 fwmark 0x2023 lookup 2022
      done
    '';
    preStop = ''
      for family in -4 -6; do
        for pref in 5200 5201 5202 5204 5205; do
          while ip "$family" rule del pref "$pref" 2>/dev/null; do :; done
        done
      done
    '';
  };
  systemd.services.vm-cgroup-nft-sync = {
    description = "Sync VM and Throne cgroups into nftables ts-priority sets";
    after = ["nftables.service"];
    requires = ["nftables.service"];
    partOf = ["nftables.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.nftables];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "1s";
      ExecStart = lib.escapeShellArgs [
        "${pkgs.python3}/bin/python3"
        "${repoRoot + "/Program Files/Scripts/vm-cgroup-nft-sync.py"}"
        "--extra-set"
        "throne_cgroups=^app-[Tt]hrone(@|-).*\\.(service|scope)$"
      ];
    };
  };
  systemd.services.tailscale-priority = {
    description = "Route Tailscale traffic directly, bypassing Throne TUN";
    after = ["tailscaled.service"];
    bindsTo = ["tailscaled.service"];
    partOf = ["tailscaled.service"];
    wantedBy = ["tailscaled.service"];
    path = [pkgs.iproute2 pkgs.coreutils];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for _ in $(seq 1 25); do
        ip link show dev ${config.services.tailscale.interfaceName} >/dev/null 2>&1 && break
        sleep 0.2
      done
      if ip link show dev ${config.services.tailscale.interfaceName} >/dev/null 2>&1; then
        ip -4 route replace 100.64.0.0/10 dev ${config.services.tailscale.interfaceName} proto static metric 1000
        ip -6 route replace fd7a:115c:a1e0::/48 dev ${config.services.tailscale.interfaceName} proto static metric 1000 || true
      fi
    '';
  };
}
