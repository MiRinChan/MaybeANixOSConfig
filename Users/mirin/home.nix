# Standalone Home Manager configuration for mirin.
{
  inputs,
  repoRoot,
  ...
}: let
  programFiles = repoRoot + "/Program Files";
  repoOverlays = import (programFiles + "/Overlays") {inherit inputs repoRoot;};
in {
  imports = [
    ./AppData
    inputs.catppuccin.homeModules.catppuccin
    inputs.sops-nix.homeManagerModules.sops
    inputs.pi-flake.homeManagerModules.default
  ];

  nixpkgs = {
    overlays = [
      repoOverlays.additions
      repoOverlays.modifications
      repoOverlays.master-packages
      repoOverlays.unstable-packages
      repoOverlays.stable-packages
      repoOverlays.d209-packages
      repoOverlays.cached-librewolf
      repoOverlays.llm-agents
      inputs.prince213.overlays.default

      (final: prev: {
        kdePackages =
          prev.kdePackages
          // {
            signon-plugin-oauth2 = final.kdePackages.callPackage (programFiles + "/Packages/signon-plugin-oauth2") {};
            signond = final.kdePackages.callPackage (programFiles + "/Packages/signond") {
              inherit (final.kdePackages) signon-plugin-oauth2;
            };
            signon-ui = final.kdePackages.callPackage (programFiles + "/Packages/signon-ui") {};
          };
      })
    ];
    config.allowUnfree = true;
  };

  home = {
    username = "mirin";
    homeDirectory = "/home/mirin";
    sessionVariables = {
      EDITOR = "code";
      BROWSER = "firefox";
      TERMINAL = "kitty";
      # Keep Firefox on XWayland: DP hotplug during display blanking can make
      # its native Wayland connection fail with a broken pipe.
      MOZ_ENABLE_WAYLAND = "0";
    };
  };

  systemd.user.startServices = "sd-switch";
  services.kdeconnect.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
