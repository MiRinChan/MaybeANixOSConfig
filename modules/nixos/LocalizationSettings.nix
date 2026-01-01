{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
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
  # i18n.inputMethod = {
  #   enabled = "fcitx5";
  #   fcitx5.addons = with pkgs; [
  #     fcitx5-chinese-addons
  #   ];
  # };
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
          "FiraCode Nerd Font"
          "Source Han Sans SC"
          "Source Han Sans"
          "Noto Sans CJK SC"
          "Noto Sans CJK"
          "Noto Sans"
        ];
        serif = [
          "FiraCode Nerd Font"
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
}
