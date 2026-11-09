# Standalone Home Manager configuration for mirin.
{
  inputs,
  repoRoot,
  ...
}: {
  imports = [
    ./AppData
    inputs.catppuccin.homeModules.catppuccin
    inputs.sops-nix.homeManagerModules.sops
  ];

  nixpkgs = {
    overlays = with inputs.self.overlays; [
      modifications
      master-packages
      unstable-packages
      stable-packages
      d209-packages
      cached-librewolf
      llm-agents
      inputs.prince213.overlays.default

      (final: prev: {
        kdePackages =
          prev.kdePackages
          // {
            signon-plugin-oauth2 = final.kdePackages.callPackage (repoRoot + "/Program Files/Packages/signon-plugin-oauth2") {};
            signon-ui = final.kdePackages.callPackage (repoRoot + "/Program Files/Packages/signon-ui") {};
          };
      })
      additions
    ];
    config.allowUnfree = true;
  };

  home = {
    username = "mirin";
    homeDirectory = "/home/mirin";
    sessionVariables = {
      EDITOR = "code --wait";
      BROWSER = "firefox";
      TERMINAL = "kitty";
    };
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "24.05";
  };

  systemd.user.startServices = "sd-switch";
  programs.home-manager.enable = true;
}
