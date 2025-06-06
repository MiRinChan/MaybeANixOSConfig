{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # GUI 生产力
    kdePackages.kcolorchooser # 颜色选择器
    kdePackages.kgpg # Gpg 加密
    kdePackages.kleopatra # Gpg 加密
    krita # 画图
    inkscape # 画图
    oculante # 看图
    furmark # 图形性能检测器
    stable.kdePackages.kdenlive # 视频剪辑
    reaper # 音频剪辑
    d209.veracrypt # 磁盘加密
    rquickshare-legacy # 快速分享
    qgis # 地理信息系统
    scrcpy3 # Android 屏传
    stable.davinci-resolve
    gimp
    tsukimi # emby

    kdePackages.powerdevil

    # Wallpaper Engine Plugin and dependence
    wallpaper-engine-kde-plugin
    kdePackages.qtwebsockets
    kdePackages.qtwebchannel
    kdePackages.qtmultimedia
    kdePackages.qtwebengine

    # 游戏
    osu-lazer
    lunar # Minecraft

    # Firefox
    stable.firefox # for internet
    stable.librewolf # for internet tool
    #cHROMIUM
    ungoogled-chromium

    # 源代码管理
    git

    # 解压
    zip
    xz
    unzip
    p7zip
    unrar

    # 工具
    fzf # fuzzy finder
    btop
    nnn # terminal file manager
    fastfetch
    texliveTeTeX

    # 杂项
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    ffmpeg_7-full # provide ffmpeg

    # 网路工具
    mtr # A network diagnostic tool
    iperf3
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses
    nekoray # Magic internet

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # 生产力

    iotop # I/O 监视
    iftop # 网络监视

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # 系统工具
    sysstat
    lm_sensors # provide `sensors` command
    ethtool
    pciutils # provide lspci
    usbutils # provide lsusb
  ];
}
