{
  config,
  inputs,
  lib,
  ...
}: let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in {
  nix = {
    settings = {
      # 启用新 nix 命令行和 flakes
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;

      # Allow mirin to specify additional substituters through flake config or
      # command-line options.
      trusted-users = ["mirin"];
      substituters = lib.mkForce [
        "https://cache.numtide.com"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        # "https://luogu-judge.cachix.org"
        # "https://niri.cachix.org"
        # "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };

    # Opinionated: disable channels
    channel.enable = true;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (name: _: "${name}=flake:${name}") flakeInputs;

    # Auto GC is managed by programs.nh in Program Files/Applications/system-tools.nix.
    optimise.automatic = true;
    optimise.dates = ["20:50"];
  };
}
