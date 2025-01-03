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
    nur.repos.shadowrz.klassy-qt6
  ];
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
