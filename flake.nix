{
  description = "Rin's computer configuration";

  inputs = {
    ### Nixpkgs ###
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pin 特定频道
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-d209.url = "github:nixos/nixpkgs/d209d800b7df2d4b05ea1266b14a47cba5da129b";
    nixpkgs-librewolf.url = "github:nixos/nixpkgs/9e92285f211dad236540fd617d7e30e0b99bc0e1";
    # Also see the package channel overlays in Program Files/Overlays/default.nix.
    ### Nixpkgs ###

    nur.url = github:nix-community/NUR;

    flatpak.url = "github:gmodena/nix-flatpak?ref=v0.4.1";

    catppuccin.url = "github:catppuccin/nix/release-25.11";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # lanzaboote for Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    solaar = {
      url = "github:Svenum/Solaar-Flake/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # C:/Users/
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    catppuccin,
    flatpak,
    home-manager,
    lanzaboote,
    nixpkgs,
    nur,
    solaar,
    ...
  }: let
    repoRoot = ./.;
    programFiles = repoRoot + "/Program Files";
    windows = repoRoot + "/Windows";
    users = repoRoot + "/Users";
    systems = ["x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
    packagePkgs = forAllSystems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
    repoOverlays = import (programFiles + "/Overlays") {inherit inputs repoRoot;};
  in {
    packages = forAllSystems (system: import (programFiles + "/Packages") packagePkgs.${system});
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = repoOverlays;

    homeConfigurations.mirin = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs repoRoot;};
      modules = [(users + "/mirin/home.nix")];
    };

    nixosConfigurations.rins = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs repoRoot;};
      modules = [
        flatpak.nixosModules.nix-flatpak
        inputs.sops-nix.nixosModules.sops
        (windows + "/System32")
        catppuccin.nixosModules.catppuccin
        nur.modules.nixos.default
        lanzaboote.nixosModules.lanzaboote
        solaar.nixosModules.default
      ];
    };
  };
}
