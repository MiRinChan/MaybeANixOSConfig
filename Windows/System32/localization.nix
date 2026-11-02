{pkgs, ...}: {
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

  # chrony 对时：中国大陆、香港、美国时间源
  services.chrony = {
    enable = true;
    extraConfig = "bindacqdevice wlp0s20f3";
  };
  networking.timeServers = [
    "ntp.tencent.com" # 腾讯 NTP 服务器
    "cn.pool.ntp.org" # 中国大陆 NTP 服务器池
    "hk.pool.ntp.org" # 香港 NTP 服务器池
    "us.pool.ntp.org" # 美国 NTP 服务器池
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
}
