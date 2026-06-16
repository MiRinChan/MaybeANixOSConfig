{pkgs, ...}: {
  programs.mosh = {
    enable = true;
    openFirewall = true;
  };

  services.usbmuxd.enable = true;

  services.pcscd = {
    enable = true;
  };

  services.udisks2.enable = true;

  programs.kdeconnect.enable = true;

  networking.firewall = rec {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
}
