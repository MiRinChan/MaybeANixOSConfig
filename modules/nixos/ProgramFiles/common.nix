{
  config,
  lib,
  pkgs,
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
    mono5 # .NET development framework
    flatpak-builder # Flatpak builder
    appstream # Software metadata handling library, proride CLI
    easyeffects # Sound effect
    qpwgraph # Graphic PipeWire Configer
    alsa-utils # provide CLI
    devenv # provide code envireoment
    kdePackages.filelight # Quickly visualize your disk space usage
    gparted
    s-tui
  ];
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.adb.enable = true;

  # Add sunshine to make my pad could connect to my computer. For entertament.
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = ["user-with-access-to-virtualbox"];
  virtualisation.virtualbox.host.enableExtensionPack = true;
}
