# 此文件定义 overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  llm-agents = inputs.llm-agents.overlays.default;

  modifications = final: prev: {
    # 禁用 ltrace 的 tests
    ltrace = prev.ltrace.overrideAttrs (_: {
      doCheck = false;
    });

    lager = inputs.nixpkgs-master.legacyPackages.${prev.stdenv.hostPlatform.system}.lager;

    # TODO: 临时修复，上游 llm-agents 下个版本修复后删掉此 override
    # codex 0.144.0: include codex-code-mode-host binary
    # https://github.com/numtide/llm-agents.nix/issues/6630
    llm-agents =
      prev.llm-agents
      // {
        codex = prev.llm-agents.codex.overrideAttrs (old: {
          cargoBuildFlags =
            (old.cargoBuildFlags or [])
            ++ [
              "--package"
              "codex-code-mode-host"
            ];
          cargoCheckFlags =
            (old.cargoCheckFlags or [])
            ++ [
              "--package"
              "codex-code-mode-host"
            ];
        });
      };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  master-packages = final: _prev: {
    master = import inputs.nixpkgs-master {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
  d209-packages = final: _prev: {
    d209 = import inputs.nixpkgs-d209 {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
  cached-librewolf = final: _prev: {
    librewolf = inputs.nixpkgs-librewolf.legacyPackages.${final.stdenv.hostPlatform.system}.librewolf;
  };
}
