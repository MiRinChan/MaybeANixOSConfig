{
  networking = {
    enableIPv6 = true;
    # 主机名称
    hostName = "rins";
    # NetworkManager
    networkmanager.enable = true;

    nftables = {
      enable = true;
      # Keep the tables that Docker, libvirt, Tailscale, and Throne add at runtime.
      flushRuleset = false;
    };

    firewall = {
      enable = true;
      checkReversePath = true;
      # libvirt default network (virbr0) needs to keep working when throne-tun
      # is up, otherwise VM NAT traffic gets treated as untrusted bridge traffic.
      trustedInterfaces = ["virbr0"];

      extraReversePathFilterRules = ''
        iifname "throne-tun" accept
      '';

      # FTP/FTPS/SFTP 2121
      # Sunshine 47984 47989 47990 48010
      # BT 9000 30042
      allowedTCPPorts = [2121 47984 47989 47990 48010 9000 30042];
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

  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
  ];

  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;
}
