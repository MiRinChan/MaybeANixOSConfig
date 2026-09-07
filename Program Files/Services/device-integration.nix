{...}: {
  programs.mosh = {
    enable = true;
    openFirewall = true;
  };

  services.usbmuxd.enable = true;

  services.pcscd = {
    enable = true;
  };

  services.udisks2.enable = true;
}
