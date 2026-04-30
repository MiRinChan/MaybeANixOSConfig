{pkgs, ...}: {
  home.packages = with pkgs; [
    reaper # 音频剪辑
    openutau # UTAU 歌声合成
  ];
}
