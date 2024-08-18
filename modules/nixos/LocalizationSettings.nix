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
  # 你永远都是中国人！是的！我们中国人自古以来就有吃苦耐劳的精神！做什么都要比别人多加一句！！！
  nix.settings.substituters = ["https://mirror.sjtu.edu.cn/nix-channels/store"];
  # 输入法
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-chinese-addons
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
      maple-mono-SC-NF
      monaspace
      sarasa-gothic
      fira-code-nerdfont
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
          "Maple Mono SC NF"
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
  system.fsPackages = [pkgs.bindfs];
  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
    };
    aggregatedFonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = config.fonts.fonts;
      pathsToLink = ["/share/fonts"];
    };
  in {
    # Create an FHS mount to support flatpak host icons/fonts
    "/usr/share/icons" = mkRoSymBind (config.system.path + "/share/icons");
    "/usr/share/fonts" = mkRoSymBind (aggregatedFonts + "/share/fonts");
  };
}
