{
  networking = {
    enableIPv6 = true;
    # 主机名称
    hostName = "rins";
    # NetworkManager
    networkmanager.enable = true;

    firewall = {
      enable = true;
      checkReversePath = true;
      # libvirt default network (virbr0) needs to keep working when throne-tun
      # is up, otherwise VM NAT traffic gets treated as untrusted bridge traffic.
      trustedInterfaces = ["virbr0"];

      extraCommands = ''
        iptables -t mangle -I nixos-fw-rpfilter 1 -i throne-tun -j RETURN
        ip6tables -t mangle -I nixos-fw-rpfilter 1 -i throne-tun -j RETURN
      '';
      extraStopCommands = ''
        iptables -t mangle -D nixos-fw-rpfilter -i throne-tun -j RETURN 2>/dev/null || true
        ip6tables -t mangle -D nixos-fw-rpfilter -i throne-tun -j RETURN 2>/dev/null || true
      '';

      # FTP/FTPS/SFTP 2121
      # Sunshine 47984 47989 47990 48010
      # BT 9000 30042
      allowedTCPPorts = [2121 47984 47989 47990 48010 9000 30042];
      allowedUDPPorts = [];
      # Sunshine 8000-8010 47998-48000
      # Mosh 60000-61000
      allowedUDPPortRanges = [
        {
          from = 47998;
          to = 48000;
        }
        {
          from = 8000;
          to = 8010;
        }
        {
          from = 60000;
          to = 61000;
        }
      ];
    };
  };

  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;
}
