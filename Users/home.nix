# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  flake-inputs,
  catppuccin,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example
    # outputs.homeManagerModules.fontConfiguration

    # You can also split up your configuration and import pieces of it here:
    ./AppData
    catppuccin.homeModules.catppuccin
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      outputs.overlays.stable-packages
      outputs.overlays.d209-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })

      (final: prev: {
        kdePackages =
          prev.kdePackages
          // {
            signon-plugin-oauth2 = final.kdePackages.callPackage ../pkgs/signon-plugin-oauth2 {};
            signond = final.kdePackages.callPackage ../pkgs/signond {
              inherit (final.kdePackages) signon-plugin-oauth2;
            };
            signon-ui = final.kdePackages.callPackage ../pkgs/signon-ui {};
          };
      })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  home = {
    username = "mirin";
    homeDirectory = "/home/mirin";
    sessionVariables = {
      EDITOR = "code";
      BROWSER = "firefox";
      TERMINAL = "kitty";
    };
  };

  # 强制定义图标主题
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # 针对 KDE 的 Qt 变量映射
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  home.packages = with pkgs; [steam];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
