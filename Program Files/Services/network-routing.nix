{
  config,
  pkgs,
  ...
}: let
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
    # Exit routing can send unmarked discovery replies through tailscale0.
    # Keep strict reverse-path checks for other traffic.
    extraReversePathFilterRules = ''
      udp dport ${toString config.services.tailscale.port} accept
      iifname "wlp0s20f3" udp sport 123 ct state established,related ct direction reply accept
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

  # Tailscale traffic must bypass Throne/sing-box interception:
  # - Mark 100.64.0.0/10 (incl. MagicDNS 100.100.100.100) and the tailnet ULA
  #   fd7a:115c:a1e0::/48 with sing-box's own bypass mark 0x2024 before its
  #   hooks (redirect/mark/queue) run, so Throne leaves them alone.
  # - Bypass interception for tailscaled's marked UDP sockets. Restore its
  #   routing mark after sing-box so exit-node transport uses the main table.
  # - Bypass interception for traffic already routed to tailscale0, including
  #   public destinations while an exit node is selected.
  # - Pin the CGNAT range to tailscale0 as a fallback so a peer without a /32
  #   in table 52 can never fall into Throne's catch-all table 2022.
  networking.nftables.tables.ts-priority = {
    family = "inet";
    content = ''
      chain output_pre {
        type filter hook output priority mangle - 2; policy accept;
        oifname "${config.services.tailscale.interfaceName}" counter meta mark set 0x00002024 ct mark set 0x00002024
        meta skuid 0 meta mark & 0x00ff0000 == 0x00080000 udp sport ${toString config.services.tailscale.port} counter ct mark set 0x00002024
        meta nfproto ipv4 ip daddr 100.64.0.0/10 meta mark set 0x00002024 ct mark set 0x00002024
        meta nfproto ipv6 ip6 daddr fd7a:115c:a1e0::/48 meta mark set 0x00002024 ct mark set 0x00002024
      }
      chain output_transport {
        type route hook output priority mangle + 3; policy accept;
        meta skuid 0 udp sport ${toString config.services.tailscale.port} ct mark 0x00002024 counter meta mark set 0x00080000
      }
    '';
  };
  systemd.services.tailscale-priority = {
    description = "Route Tailscale traffic directly, bypassing Throne TUN";
    after = ["tailscaled.service"];
    requires = ["tailscaled.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.iproute2];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ip route replace 100.64.0.0/10 dev tailscale0 proto static metric 1000
    '';
  };
}
