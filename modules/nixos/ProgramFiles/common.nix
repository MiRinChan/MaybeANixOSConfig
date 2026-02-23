{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    screen # Screen
    kdePackages.ksvg # Require by SDDM
    alejandra # Code formater
    catppuccin # Prettier system color
    plymouth # Prettier startup
    eza # Prettier ls
    kdePackages.kgpg # kGpg
    kdePackages.kleopatra # kleopatra
    flatpak-builder # Flatpak builder
    appstream # Software metadata handling library, proride CLI
    easyeffects # Sound effect
    qpwgraph # Graphic PipeWire Configer
    alsa-utils # provide CLI
    devenv # provide code envireoment
    kdePackages.filelight # Quickly visualize your disk space usage
    gparted # provide a gui for parted
    pkgs.sbctl # For debugging and troubleshooting Secure Boot.
    libarchive # provide bsdcat bsdcpio bsdtar bsdunzip
    jq # provide a json proceessor
    qemu # qemu
    pkgs.stable.kde-rounded-corners # Rounded
    ntfs3g # NTFS
    ffmpeg
    gphoto2
    mpv
    kdePackages.kdecoration
    cmake
    gcc
    gdb
    nh # seem also programs.nh
    nur.repos.linyinfeng.easylpac
    lpac
    android-tools
    papirus-icon-theme
    kdePackages.breeze-icons
    adwaita-icon-theme
  ];
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 30d --keep 10";
    flake = "/home/mirin/nixos-config"; # sets NH_OS_FLAKE variable for you
  };

  programs.throne = {
    enable = true;
    tunMode.enable = true;
    tunMode.setuid = false;
  };

  services.pcscd = {
    enable = true;
  };

  services.udisks2.enable = true;

  # Note: https://www.tomoliver.net/posts/using-an-slr-as-a-webcam-nixos
}
