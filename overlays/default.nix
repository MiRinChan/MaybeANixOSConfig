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
    nekoray = (inputs.nekoflake.packages.${prev.system}.nekoray or {}).overrideAttrs (oldAttrs: {
      # 2. 覆盖 (override) 原有的 cmakeFlags
      cmakeFlags =
        (oldAttrs.cmakeFlags or [])
        ++ [
          "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
        ];
    });
    klassy-qt6 = inputs.klassy.packages.${prev.system}.klassy-qt6 or {};
    shanocast = (inputs.shanocast.packages.${prev.system}.shanocast or {}).overrideAttrs (oldAttrs: {
      # 1. 过滤 CXXFLAGS（C++ 编译标志）
      #    使用 builtins.filter 移除列表中的 "-Werror" 字符串
      CXXFLAGS = builtins.filter (flag: flag != "-Werror") (oldAttrs.CXXFLAGS or "");

      # 2. 过滤 NIX_CFLAGS_COMPILE（Nix 通用编译标志，也常包含 -Werror）
      NIX_CFLAGS_COMPILE = builtins.filter (flag: flag != "-Werror") (oldAttrs.NIX_CFLAGS_COMPILE or "");

      # 3. 如果编译失败是由于特定的警告被提升为错误，
      #    可以尝试添加 -Wno-XXX 来禁用该警告，例如：
      # NIX_CXXFLAGS_COMPILE = (oldAttrs.NIX_CXXFLAGS_COMPILE or "") + " -Wno-maybe-uninitialized";
    });
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
  d209-packages = final: _prev: {
    d209 = import inputs.nixpkgs-d209 {
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
