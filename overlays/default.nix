# 此文件定义 overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    #     example = prev.example.overrideAttrs (oldAttrs: rec {
    #     ...
    #     });

    # kdePackages =
    #   prev.kdePackages
    #   // {
    #     kwin = prev.kdePackages.kwin.overrideAttrs (old: {
    #       patches =
    #         (old.patches or [])
    #         ++ [
    #           ./fix-blur.patch
    #         ];
    #     });
    #   };
    # nekoray = (inputs.nekoflake.packages.${prev.stdenv.hostPlatform.system}.nekoray or {}).overrideAttrs (oldAttrs: {
    #   # 2. 覆盖 (override) 原有的 cmakeFlags
    #   cmakeFlags =
    #     (oldAttrs.cmakeFlags or [])
    #     ++ [
    #       "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    #     ];
    # });
    klassy-qt6 = inputs.klassy.packages.${prev.stdenv.hostPlatform.system}.klassy-qt6 or {};
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
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
  # RinsRepo-packages = final: _prev: {
  #   RinsRepo = import inputs.RinsRepo {
  #     system = final.stdenv.hostPlatform.system;
  #     config.allowUnfree = true;
  #   };
  # };
}
