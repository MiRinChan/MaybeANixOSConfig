{
  description = "Rin's computer configuration";

  inputs = {
    ### Nixpkgs ###
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pin 特定频道
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    ### Nixpkgs ###

    # NUR Package
    nur.url = github:nix-community/NUR;

    # sandbox NixPak
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpak-pkgs.url = "github:nixpak/pkgs";

    # Flatpak
    flatpak.url = "github:gmodena/nix-flatpak?ref=v0.4.1";

    # pretty theme
    catppuccin.url = "github:catppuccin/nix";

    # lanzaboote for Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # RinsRepo = {
    #   url = "github:MiRinChan/MaybeSomeNixPackages";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # C:/Users/
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # url = "github:nix-community/home-manager/release-24.05";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-stable,
    nixpak,
    nixpak-pkgs,
    flatpak,
    alejandra,
    catppuccin,
    home-manager,
    nur,
    lanzaboote,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # 支持的系统架构
    systems = [
      "x86_64-linux"
      # "aarch64-linux"
    ];
    # 这是一个通过调用您传递给它的函数来生成属性的函数，每个系统作为参数
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # 定制的包
    # 可用 'nix build', 'nix shell' 等
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # nix 文件的格式化程序，可通过 'nix fmt'
    # 除了 “alejandra” 之外的其他选项包括“nixpkgs-fmt”
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # 定制的包和修改, 导出为 overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable nixos modules you might want to export
    # 您可能想要导出的可重复使用的 nixos 模块
    # 这些通常是您要上传到 nixpkgs 的内容
    nixosModules = import ./modules/nixos;
    # 您可能想要导出可重复使用的 home-manager 模块
    # 这些通常是您要上传到 home-manager 的内容
    homeManagerModules = import ./modules/home-manager;
    # NixOS 配置入口点
    # 可用 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      # 主机名
      rins = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          flatpak.nixosModules.nix-flatpak
          # > 主要 NixOS 配置文件 <
          ./System32/configuration.nix
          # home manager
          home-manager.nixosModules.home-manager
          catppuccin.nixosModules.catppuccin
          nur.nixosModules.nur
          lanzaboote.nixosModules.lanzaboote

          {
            home-manager.useUserPackages = true;
            home-manager.users.mirin = import ./Users/home.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit inputs outputs;
            };
            home-manager.extraSpecialArgs.flake-inputs = inputs;
            home-manager.extraSpecialArgs.catppuccin = catppuccin;
          }
        ];
      };
    };
  };
}
