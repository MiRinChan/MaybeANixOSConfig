{
  programs.mosh = {
    enable = true;
    openFirewall = true;
  };

  services = {
    usbmuxd.enable = true;
    pcscd.enable = true;
    udisks2.enable = true;

    # NixOS only grants the usbmux group. Without the upstream deconfigure
    # rule, iPad/iPhone stay in the PTP configuration and show up as charging.
    udev.extraRules = ''
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{PRODUCT}=="5ac/12[9a][0-9a-f]/*|5ac/190[1-5]/*", ACTION=="add", ENV{USBMUX_SUPPORTED}="1", ATTR{bConfigurationValue}="0", OWNER="usbmux"
    '';
  };
}
