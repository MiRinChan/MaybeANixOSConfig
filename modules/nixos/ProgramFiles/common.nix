{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    screen
    kdePackages.ksvg
    alejandra
    catppuccin
    plymouth
    eza
    kdePackages.kgpg
    kdePackages.kleopatra
    mono5
    flatpak-builder
    appstream
    easyeffects
    qpwgraph
    alsa-utils
  ];
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  programs.adb.enable = true;

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = ["user-with-access-to-virtualbox"];
  virtualisation.virtualbox.host.enableExtensionPack = true;
}
