{
  config,
  inputs,
  lib,
  ...
}: {
  nix = {
    settings = {
      # Compile one package at a time with eight workers.
      max-jobs = 1;
      cores = 8;
      extra-sandbox-paths = [config.programs.ccache.cacheDir];

      # 启用新 nix 命令行和 flakes
      experimental-features = ["nix-command" "flakes"];
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = lib.mapAttrsToList (name: _: "${name}=flake:${name}") config.nix.registry;

      # Allow mirin to specify additional substituters through flake config or
      # command-line options.
      trusted-users = ["mirin"];
      substituters = lib.mkForce [
        "https://cache.numtide.com"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://winapps.cachix.org"
        # "https://luogu-judge.cachix.org"
        # "https://niri.cachix.org"
        # "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="
      ];
    };

    # Opinionated: disable channels
    channel.enable = true;

    # Opinionated: make flake registry and nix path match flake inputs
    nixPath = config.nix.settings.nix-path;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) (lib.filterAttrs (_: lib.isType "flake") inputs);

    # Auto GC is managed by programs.nh in Program Files/Applications/system-tools.nix.
    optimise = {
      automatic = true;
      dates = ["20:50"];
    };
  };

  programs.ccache.enable = true;

  # Keep build memory below desktop needs and prefer reclaiming build processes.
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "12G";
    MemoryMax = "16G";
    MemorySwapMax = "4G";
    OOMScoreAdjust = 500;
    Nice = 10;
    CPUWeight = 25;
    IOWeight = 25;
  };
}
