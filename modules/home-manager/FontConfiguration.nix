{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # 字体
  fonts = {
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
    };
  };
}
