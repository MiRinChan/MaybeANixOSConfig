# 系统环境配置文件
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    outputs.nixosModules.theProgramInstallForAllUsers
    outputs.nixosModules.localizationSettings
    outputs.nixosModules.nvidiaDriver
    outputs.nixosModules.ADBDriver
    outputs.nixosModules.soundSettings
    outputs.nixosModules.FHSEnviroment

    # 用户配置
    ./UsersConf.nix
    # 硬件配置
    ./hardware-configuration.nix
  ];
  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      outputs.overlays.stable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  catppuccin.flavor = "mocha";
  catppuccin.enable = true;

  # NixOS，启动！
  boot = {
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    loader = {
      systemd-boot = {
        enable = lib.mkForce false; # lanzaboote replace it. btw keep option.
        # enable = true;
        consoleMode = "max";
      };

      # grub = {
      #   enable = true;
      #   device = "nodev";
      #   efiSupport = true;
      #   gfxmodeEfi = "auto";
      #   gfxmodeBios = "auto";
      #   gfxpayloadEfi = "auto";
      #   gfxpayloadBios = "auto";
      # };

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
      "kvm.enable_virt_at_load=0" # VirtualBox
      "nowatchdog" # forgot it transport endpoint is not connected
    ];

    kernelModules = ["nvidia" "v4l2loopback"]; # v4l2loopback: webcam.
    extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 max_buffers=2 video_nr=9 card_label="虚拟摄像头"
    '';

    # pkgs.linuxPackages == lts
    # pkgs.linuxPackages_latest == stable
    kernelPackages = pkgs.linuxPackages_latest;

    #kernelPackages = pkgs.linuxPackages_latest;
    #kernelPackages = pkgs.linuxPackages_xanmod_stable;
    #kernelPackages = pkgs.linuxKernel.packages.linux_zen;

    plymouth = {
      enable = true;
    };
    initrd.systemd.enable = true;

    supportedFilesystems = ["ntfs"];
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # 启用新 nix 命令行和 flakes
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };
    # Opinionated: disable channels
    channel.enable = true;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

    # Auto GC
    # Added in modules/nixos/ProgramFiles/common.nix
    # gc = {
    #   automatic = true;
    #   options = "--delete-older-than 30d";
    #   dates = "Sun 19:00";
    # };
    optimise.automatic = true;
    optimise.dates = ["20:50"];
  };

  networking = {
    # 主机名称
    hostName = "rins";
    # NetworkManager
    networkmanager.enable = true;

    firewall = {
      enable = true;
      # FTP/FTPS/SFTP 2121
      # Sunshine 47984 47989 47990 48010
      # Wallpaper Engine 7889
      # BT 9000 30042
      allowedTCPPorts = [2121 7889 47984 47989 47990 48010 9000 30042];
      # Wallpaper Engine 7884
      allowedUDPPorts = [];
      # Sunshine 8000-8010 47998-48000
      allowedUDPPortRanges = [
        {
          from = 47998;
          to = 48000;
        }
        {
          from = 8000;
          to = 8010;
        }
      ];
    };
  };

  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;

  # 图形化
  services = {
    xserver.enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
    displayManager.sddm.wayland.enable = true;
  };

  # Make electron and Chrome happy.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  programs.dconf.enable = true;

  # Flatpak
  services.flatpak.enable = true;
  services.flatpak.remotes = [
    {
      name = "flathub-beta";
      location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
    }
    {
      name = "flathub";
      location = "https://dl.flathub.org/repo/";
    }
  ];
  # services.flatpak.update.onActivation = true;
  services.flatpak.overrides = {
    global = {
      # Force Wayland by default
      Context.sockets = ["wayland" "!x11" "!fallback-x11"];

      Context.filesystems = "xdg-config/fontconfig:ro";

      Environment = {
        # Fix un-themed cursor in some Wayland apps
        XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";

        # Force correct theme for some GTK apps
        GTK_THEME = "Adwaita:dark";
      };
    };
  };

  xdg.portal.enable = true;

  # Stop wating after I want shut down my computer. However we should check by "$ journalctl --boot -1 -xe" to find why.
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
    DefaultStartLimitBurst = "20s";
    DefaultStartLimitIntervalSec = "20s";
  };
  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=10s
    DefaultStartLimitBurst=20s
    DefaultStartLimitIntervalSec=20s
  '';

  services.udev.extraRules = ''
    # Galaxy Flasher
    SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
  '';

  # Enable binfmt emulation.
  # boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
