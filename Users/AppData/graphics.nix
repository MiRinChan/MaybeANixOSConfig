{pkgs, ...}: {
  home.packages = with pkgs; [
    krita # 画图
    inkscape # 画图
    gimp
    digikam
    stable.kdePackages.kdenlive # 视频剪辑
    stable.oculante # 看图
  ];
}
