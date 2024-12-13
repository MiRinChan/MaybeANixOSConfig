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
  };

  fix-kio-gdrive = final: prev: {
    kdePackages =
      prev.kdePackages
      // {
        signon-plugin-oauth2 = final.kdePackages.callPackage ../pkgs/signon-plugin-oauth2 {};
        signond = final.kdePackages.callPackage ../pkgs/signond {
          inherit (final.kdePackages) signon-plugin-oauth2;
        };
        signon-ui = final.kdePackages.callPackage ../pkgs/signon-ui {};
      };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
  # RinsRepo-packages = final: _prev: {
  #   RinsRepo = import inputs.RinsRepo {
  #     system = final.system;
  #     config.allowUnfree = true;
  #   };
  # };
}
