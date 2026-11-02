# 此文件定义 overlays
{
  inputs,
  repoRoot,
  ...
}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import (repoRoot + "/Program Files/Packages") final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  llm-agents = inputs.llm-agents.overlays.shared-nixpkgs;

  modifications = final: prev: let
    withCcache = package: package.override {stdenv = final.ccacheStdenv;};
  in {
    # Share the compiler cache between NixOS and standalone Home Manager.
    ccacheWrapper = prev.ccacheWrapper.override {
      extraConfig = ''
        export CCACHE_DIR=/var/cache/ccache
        export CCACHE_MAXSIZE=20GiB
        export CCACHE_COMPRESS=1
        export CCACHE_UMASK=007
        export CCACHE_COMPILERCHECK=content
        export CCACHE_SLOPPINESS=random_seed
        export CCACHE_BASEDIR="''${NIX_BUILD_TOP:-/build}"
        # The first system build can run before the cache directory exists.
        if [ ! -d "$CCACHE_DIR" ] || [ ! -w "$CCACHE_DIR" ]; then
          export CCACHE_DISABLE=1
        fi
      '';
    };

    digikam = withCcache prev.digikam;
    # Use the upstream GPU-enabled binary unless local changes require compilation.
    ffmpeg_7-full = let
      package = prev.ffmpeg_7-full;
      upstream = inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.ffmpeg_7-full;
    in
      if package.drvPath == upstream.drvPath
      then package
      else withCcache package;

    # 禁用 ltrace 的 tests
    ltrace = prev.ltrace.overrideAttrs (_: {
      doCheck = false;
    });

    kdePackages = prev.kdePackages.overrideScope (_kdeFinal: kdePrev: {
      # Always build the wallpaper package on this machine. Do not download
      # its outputs from any configured binary cache.
      plasma-workspace-wallpapers = kdePrev.plasma-workspace-wallpapers.overrideAttrs (_: {
        allowSubstitutes = false;
        preferLocalBuild = true;
      });

      # kwin-x11 6.7.4 uses ECM 6.26 but omits it from nativeBuildInputs.
      kwin-x11 = kdePrev.kwin-x11.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [kdePrev.extra-cmake-modules];
        cmakeFlags =
          (old.cmakeFlags or [])
          ++ ["-DECM_DIR=${kdePrev.extra-cmake-modules}/share/ECM/cmake"];
        propagatedBuildInputs =
          (old.propagatedBuildInputs or [])
          ++ (kdePrev.kwin.propagatedBuildInputs or []);
      });
    });

    kde-rounded-corners = (withCcache prev.kde-rounded-corners).overrideAttrs (_: {
      version = "0.11.0";
      src = prev.fetchFromGitHub {
        owner = "matinlotfali";
        repo = "KDE-Rounded-Corners";
        tag = "v0.11.0";
        hash = "sha256-rdVXukBh7doyuZaFGVQghwKqkWGtuLOXxJgvZbZG0hQ=";
      };
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
  cached-librewolf = final: _prev: {
    librewolf = inputs.nixpkgs-librewolf.legacyPackages.${final.stdenv.hostPlatform.system}.librewolf;
  };
}
