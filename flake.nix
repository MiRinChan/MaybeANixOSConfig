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

    nur.url = "github:nix-community/NUR";

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

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mooling-nix-packages = {
      url = "github:Mooling0602/nix-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    prince213 = {
      url = "github:Prince213/nix-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    b-launcher = {
      url = "github:cubk1/b-launcher";
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
    sops-nix,
    ...
  }: let
    repoRoot = ./.;
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux"];
  in {
    packages = forAllSystems (system:
      import (repoRoot + "/Program Files/Packages") (import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      }));
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = import (repoRoot + "/Program Files/Overlays") {inherit inputs repoRoot;};

    homeConfigurations.mirin = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs repoRoot;};
      modules = [./Users/mirin/home.nix];
    };

    nixosConfigurations.rins = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs repoRoot;};
      modules = [
        flatpak.nixosModules.nix-flatpak
        sops-nix.nixosModules.sops
        ./Windows/System32
        catppuccin.nixosModules.catppuccin
        nur.modules.nixos.default
        lanzaboote.nixosModules.lanzaboote
      ];
    };
  };
}
