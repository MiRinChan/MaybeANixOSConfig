{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    kdePackages.kcolorchooser
    kde-rounded-corners
    btop
    klassy
    LightlyShaders

    furmark

    osu-lazer

    kdePackages.kgpg
    kdePackages.kleopatra

    krita
    inkscape

    ffmpeg_7-full

    # Firefox
    firefox # for internet
    librewolf # for internet tool

    ungoogled-chromium #cHROMIUM

    nekoray # Magic internet

    git # git

    nnn # terminal file manager

    # 解压
    zip
    xz
    unzip
    p7zip

    # utils
    fzf # fuzzy finder

    # misc
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

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

    # productivity

    iotop # io monitoring
    iftop # network monitoring

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
  ];
}
