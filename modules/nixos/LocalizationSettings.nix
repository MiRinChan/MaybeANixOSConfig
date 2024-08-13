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
      fira-code-nerdfont
      sarasa-gothic
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      source-han-mono
      source-han-sans
      source-han-serif
      wqy_zenhei
      migu
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
    };
  };
}
