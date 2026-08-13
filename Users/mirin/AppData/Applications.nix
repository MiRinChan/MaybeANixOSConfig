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
    tsuyaku # Wayland 实时音频翻译
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

  xdg.configFile."tsuyaku/config.toml" = {
    force = true;
    text = ''
      [audio]
      target_object = "@DEFAULT_AUDIO_SINK@"
      sample_rate = 16000

      [vad]
      model_path = "silero_vad.onnx"
      threshold = 0.35
      min_silence_duration = 0.65
      min_speech_duration = 0.10
      max_speech_duration = 15.0
      pre_speech_padding_ms = 350

      [asr]
      model_path = "model.int8.onnx"
      tokens_path = "tokens.txt"
      language = "ja"
      num_threads = 2

      [translate]
      enabled = false
      source_language = "ja"
      target_language = "zh"
      endpoint = ""
      api_key = ""
      model = ""
      temperature = 0.2
      max_tokens = 256
      context_history_size = 3
      disable_thinking = false

      [ui]
      font_size = 18
      opacity = 0.85
      width = 720
      show_source_text = true
    '';
  };
}
