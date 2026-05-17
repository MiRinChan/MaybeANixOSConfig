{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: let
  # The NUR derivation rebuilds the bundled TTF and currently fails on this
  # nixpkgs snapshot, so reuse upstream's generated TTF for font installation.
  gallantFont = pkgs.nur.repos.prince213.gallant.overrideAttrs (_: {
    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';
  });
  gallantConsoleFont =
    pkgs.runCommand "${gallantFont.pname}-console-font-${gallantFont.version}" {
      nativeBuildInputs = [pkgs.bdf2psf];
    } ''
      mkdir -p "$out/share/consolefonts"
      cd ${pkgs.bdf2psf}/share/bdf2psf
      bdf2psf \
        --fb "${gallantFont.src}/gallant.bdf" \
        standard.equivalents \
        ascii.set+useful.set+linux.set \
        512 \
        "$out/share/consolefonts/gallant.psfu"
    '';
in {
  nixpkgs.config = {
    problems.handlers = {
      gallant.broken = "warn"; # or "ignore"
    };
  };

  # 设置时区
  time.timeZone = "Asia/Shanghai";
  # 语言和编码
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "C.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "zh_CN.UTF-8/UTF-8"
  ];
  # 你永远都是中国人！
  nix.settings = {
    # given the users in this list the right to specify additional substituters via:
    #    1. `nixConfig.substituters` in `flake.nix`
    #    2. command line args `--options substituters http://xxx`
    trusted-users = ["mirin"];

    substituters = lib.mkForce [
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      # "https://luogu-judge.cachix.org"
      # "https://niri.cachix.org"
      # "https://cache.garnix.io"
    ];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  # NTP 服务器 (中国大陆服务器)
  # To fix: Wating sync time for a long time. Thanks to Ryan Yin!
  # Sep 14 20:42:51 rins systemd-timesyncd[1114]: Timed out waiting for reply from 193.182.111.12:123 (0.nixos.pool.ntp.org).
  # Sep 14 20:44:11 rins systemd[1]: user@1000.service: Deactivated successfully.
  networking.timeServers = [
    "ntp.tencent.com" # 腾讯 NTP 服务器
    "ntp.tuna.tsinghua.edu.cn" # 清华大学 NTP 服务器
    # "time.cloudflare.com" # Cloudflare NTP 服务器 uncomment this if network is OK.
  ];
  # 输入法
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      fcitx5-pinyin-moegirl
      fcitx5-pinyin-zhwiki
      fcitx5-pinyin-minecraft
    ];
  };
  # 字体
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      maple-mono.NF-CN
      monaspace
      sarasa-gothic
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      source-han-mono
      source-han-sans
      source-han-serif
      gallantFont
    ];
    fontconfig = {
      enable = true;
      # 默认字体
      defaultFonts = {
        monospace = [
          "Maple Mono NF CN Medium"
          "FiraCode Nerd Font Mono"
          "Source Han Mono SC"
          "Source Han Mono"
          "Noto Sans Mono CJK SC"
          "Noto Sans Mono CJK"
          "Noto Sans Mono"
        ];
        sansSerif = [
          "Source Han Sans SC"
          "Source Han Sans"
          "Noto Sans CJK SC"
          "Noto Sans CJK"
          "Noto Sans"
        ];
        serif = [
          "Source Han Serif SC"
          "Source Han Serif"
          "Noto Serif CJK SC"
          "Noto Serif CJK"
          "Noto Serif"
        ];
        emoji = ["Noto Color Emoji"];
      };
      localConf = ''
        <!-- Make Emoji happy. -->
        <match target="font">
          <test name="family" qual="first">
            <string>Noto Color Emoji</string>
          </test>
          <edit mode="assign" name="antialias">
            <bool>false</bool>
          </edit>
        </match>
      '';
    };
  };

  console = {
    packages = [gallantConsoleFont];
    font = "${gallantConsoleFont}/share/consolefonts/gallant.psfu";
    earlySetup = true;
    keyMap = "us";
  };
}
