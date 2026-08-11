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
}
