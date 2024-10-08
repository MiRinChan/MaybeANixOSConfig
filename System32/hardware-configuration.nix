# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["vmd" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9c66d2fc-3fa9-4417-96f5-70ee3355343d";
    fsType = "btrfs";
    options = ["subvol=root" "compress=zstd"];
  };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/539c69af-bf5d-496f-aabc-e8044e6bc35a";

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/9c66d2fc-3fa9-4417-96f5-70ee3355343d";
    fsType = "btrfs";
    options = ["subvol=home" "compress=zstd"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/9c66d2fc-3fa9-4417-96f5-70ee3355343d";
    fsType = "btrfs";
    options = ["subvol=nix" "noatime" "compress=zstd"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/47E5-CB94";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/d2e686f1-badb-4a65-90e5-d988f9055305";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
