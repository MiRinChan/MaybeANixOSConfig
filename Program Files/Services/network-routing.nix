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
  ntpWifiFirewall = pkgs.writeShellScript "ntp-wifi-firewall" ''
    set -euo pipefail
    rule=(-i wlp0s20f3 -p udp --sport 123 -m conntrack --ctstate ESTABLISHED,RELATED --ctdir REPLY -j RETURN)
    for iptables in ${pkgs.iptables}/bin/iptables ${pkgs.iptables}/bin/ip6tables; do
      case "$1" in
        start)
          "$iptables" -w -t mangle -C nixos-fw-rpfilter "''${rule[@]}" 2>/dev/null ||
            "$iptables" -w -t mangle -I nixos-fw-rpfilter 1 "''${rule[@]}"
          ;;
        stop)
          "$iptables" -w -t mangle -D nixos-fw-rpfilter "''${rule[@]}" 2>/dev/null || true
          ;;
      esac
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
    after = ["network.target" "firewall.service"];
    before = ["chronyd.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.iproute2 pkgs.nftables];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${ntpWifiRoutes}
      ${ntpWifiFirewall} start
      ${pkgs.nftables}/bin/nft -f - <<'NFT'
      add table inet ntp_wifi_direct
      add chain inet ntp_wifi_direct output { type route hook output priority mangle - 3; policy accept; }
      flush chain inet ntp_wifi_direct output
      add rule inet ntp_wifi_direct output udp dport 123 counter meta mark set 0x2024 ct mark set 0x2024
      NFT
    '';
    preStop = ''
      nft delete table inet ntp_wifi_direct 2>/dev/null || true
      ${ntpWifiFirewall} stop
      for family in -4 -6; do
        while ip "$family" rule del pref 5101 ipproto udp dport 123 table 123 2>/dev/null; do :; done
        ip "$family" route flush table 123
      done
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
    extraCommands = ''
      ${ntpWifiFirewall} start
      iptables -t mangle -C nixos-fw-rpfilter -p udp --dport ${toString config.services.tailscale.port} -j RETURN 2>/dev/null || \
        iptables -t mangle -I nixos-fw-rpfilter 1 -p udp --dport ${toString config.services.tailscale.port} -j RETURN
      ip6tables -t mangle -C nixos-fw-rpfilter -p udp --dport ${toString config.services.tailscale.port} -j RETURN 2>/dev/null || \
        ip6tables -t mangle -I nixos-fw-rpfilter 1 -p udp --dport ${toString config.services.tailscale.port} -j RETURN
    '';
    extraStopCommands = ''
      ${ntpWifiFirewall} stop
      iptables -t mangle -D nixos-fw-rpfilter -p udp --dport ${toString config.services.tailscale.port} -j RETURN 2>/dev/null || true
      ip6tables -t mangle -D nixos-fw-rpfilter -p udp --dport ${toString config.services.tailscale.port} -j RETURN 2>/dev/null || true
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
  systemd.services.tailscale-priority = {
    description = "Route Tailscale traffic directly, bypassing Throne TUN";
    after = ["tailscaled.service"];
    requires = ["tailscaled.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.nftables pkgs.iproute2];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      nft delete table inet ts-priority 2>/dev/null || true
      nft -f - <<'NFT'
      table inet ts-priority {
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
      }
      NFT
      ip route replace 100.64.0.0/10 dev tailscale0 proto static metric 1000
    '';
  };
}
