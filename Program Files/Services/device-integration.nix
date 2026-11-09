{
  programs.mosh = {
    enable = true;
    openFirewall = true;
  };

  services = {
    usbmuxd.enable = true;
    pcscd.enable = true;
    udisks2.enable = true;
  };
}
