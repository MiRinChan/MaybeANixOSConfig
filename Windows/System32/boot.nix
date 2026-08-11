{
  config,
  lib,
  pkgs,
  ...
}: {
  # NixOS，启动！
  boot = {
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    loader = {
      systemd-boot = {
        enable = lib.mkForce false; # lanzaboote replace it.
        consoleMode = "max";
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "nvidia-drm.modeset=1" # Enable kernel modesetting for NVIDIA graphics
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Preserve video memory allocations across suspend/resume
      "nvidia.NVreg_TemporaryFilePath=/var/tmp" # Set temporary file path for NVIDIA driver
      "nvidia.NVreg_UsePageAttributeTable=1" # Enable NVIDIA Page Attribute Table
      "nvidia.NVreg_EnablePCIeGen3=1" # Enable PCIe Gen3 for NVIDIA
      "nowatchdog" # forgot it transport endpoint is not connected
    ];

    kernelModules = ["nvidia" "v4l2loopback"]; # v4l2loopback: webcam.
    extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 max_buffers=2 video_nr=9 card_label="虚拟摄像头"
    '';

    # pkgs.linuxPackages == lts
    # pkgs.linuxPackages_latest == stable
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;

    #kernelPackages = pkgs.linuxPackages_latest;
    #kernelPackages = pkgs.linuxPackages_xanmod_stable;
    #kernelPackages = pkgs.linuxKernel.packages.linux_zen;

    plymouth.enable = true;
    initrd.systemd.enable = true;

    supportedFilesystems = ["ntfs"];
  };
}
