# 此文件定义 overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # 禁用 ltrace 的 tests
    ltrace = prev.ltrace.overrideAttrs (_: {
      doCheck = false;
    });

    lager = inputs.nixpkgs-master.legacyPackages.${prev.stdenv.hostPlatform.system}.lager;
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
}
