{
  config,
  lib,
  pkgs,
  ...
}: {
  services.udiskie = {
    enable = true;
    settings = {
      # workaround for
      # https://github.com/nix-community/home-manager/issues/632
      program_options = {
        file_manager = "${pkgs.kdePackages.dolphin}";
      };
    };
  };

  home.packages = with pkgs; [
    # GUI 生产力
    kdePackages.kcolorchooser # 颜色选择器
    furmark # 图形性能检测器
    d209.veracrypt # 磁盘加密
    rquickshare-the-legacy # 快速分享
    stable.qgis # 地理信息系统
    scrcpy3 # Android 屏传
    tsukimi # emby
    graalvmPackages.graalvm-ce
    xleak
    csvkit

    # Firefox
    stable.firefox # for internet
    librewolf # for internet tool
    #cHROMIUM
    ungoogled-chromium

    # 解压
    zip
    unzip
    p7zip
    unrar

    # 工具
    fzf # fuzzy finder
    btop
    nnn # terminal file manager
    fastfetch
    llm-agents.opencode # AI coding agent for the terminal
    texliveTeTeX
    sqlitebrowser

    # 杂项
    file
    tree
    ffmpeg_7-full # provide ffmpeg
    ripgrep

    # 网路工具
    mtr # A network diagnostic tool
    iperf3
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # 生产力

    iotop # I/O 监视
    iftop # 网络监视

    # system call monitoring
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
