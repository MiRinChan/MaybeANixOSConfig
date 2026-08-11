{
  config,
  pkgs,
  ...
}: {
  programs.throne = {
    enable = true;
    tunMode.enable = true;
    # tunMode.setuid = true;
    # package = pkgs.stable.throne;
  };

  services.tailscale.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [config.services.tailscale.interfaceName];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [config.services.tailscale.port];
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
          meta nfproto ipv4 ip daddr 100.64.0.0/10 meta mark set 0x00002024 ct mark set 0x00002024
          meta nfproto ipv6 ip6 daddr fd7a:115c:a1e0::/48 meta mark set 0x00002024 ct mark set 0x00002024
        }
      }
      NFT
      ip route replace 100.64.0.0/10 dev tailscale0 proto static metric 1000
    '';
  };
}
