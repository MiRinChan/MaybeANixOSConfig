{
  lib,
  pkgs,
  ...
}: let
  nohangConfigRaw = pkgs.writeText "nohang-rins-raw.conf" ''
    ## Android-like tiered OOM policy for host `rins` (NixOS + KDE Plasma 6 Wayland).
    ##
    ## Victim priority (reclaimed first -> last):
    ##   Tier 4 (+400..+900):  expendable background jobs (nix-daemon, baloo, compilers)
    ##   Tier 3 (+200..+350):  browser tabs first (+350), then browser helper processes (+200)
    ##   Tier 2 (+150):        regular user GUI applications in app.slice
    ##   Tier 1 (-500..-650):  protected workloads (terminals, tmux, SSH, coding agents, VMs)
    ##   Tier 0 (-1500):       system & KDE Plasma 6 desktop core (immune; badness = 0)

    # 0. Check kernel messages for fallback kernel OOM events
    @check_kmsg

    # 1. Common zram settings
    # ZRAM is 50% of RAM with NVMe swap fallback, so MemAvailable + SwapFree + PSI
    # already track pressure accurately without needing a separate ZRAM ceiling.
    zram_checking_enabled = False

    # 2. Common PSI settings
    psi_checking_enabled = True
    psi_path = /proc/pressure/memory
    psi_metrics = full_avg10
    psi_excess_duration = 15
    psi_post_action_delay = 15

    # 3. Poll rate
    fill_rate_mem = 6000
    fill_rate_swap = 2000
    fill_rate_zram = 4000
    max_sleep = 3
    min_sleep = 0.1

    # 4. Warnings and notifications
    post_action_gui_notifications = True
    hide_corrective_action_type = False
    low_memory_warnings_enabled = True
    warning_exe =
    warning_threshold_min_mem = 15 %
    warning_threshold_min_swap = 20 %
    warning_threshold_max_zram = 45 %
    warning_threshold_max_psi = 10
    min_post_warning_delay = 60
    env_cache_time = 300

    # 5. Soft threshold (SIGTERM first, like graceful app reclamation)
    soft_threshold_min_mem = 5 %
    soft_threshold_min_swap = 10 %
    soft_threshold_max_zram = 55 %
    soft_threshold_max_psi = 40

    # 6. Hard threshold (SIGKILL to prevent desktop lockup)
    hard_threshold_min_mem = 2 %
    hard_threshold_min_swap = 4 %
    hard_threshold_max_zram = 60 %
    hard_threshold_max_psi = 80

    # 7. Customize victim selection (Android-style priority tiers)
    ignore_positive_oom_score_adj = False

    # --- Tier 4: Expendable background jobs (reclaimed FIRST) ---
    # nix-daemon and kde-baloo already carry OOMScoreAdjust = 500; boost them further
    # so builds and file indexing always yield before interactive desktop workloads.
    @BADNESS_ADJ_RE_CGROUP_V2 400 /// ^/system\.slice/nix-daemon\.service$
    @BADNESS_ADJ_RE_NAME 400 /// ^\.?baloo(_file|runner)
    @BADNESS_ADJ_RE_NAME 500 /// ^\.?(cc1|cc1plus|clang|rustc|cargo|ld(\.(bfd|gold|lld))?$|lld$|mold$|javac$|cmake$|ninja$|ffmpeg|aria2c)

    # --- Tier 3: Browser tabs / web content renderers (reclaimed SECOND) ---
    # Reclaim individual Firefox / LibreWolf website tabs (+350) before shared
    # browser helpers (+200, such as WebExtensions / RDD / Utility), and before
    # killing the main browser process or regular GUI apps (+150).
    # (Chromium/Electron renderers already carry kernel oom_score_adj = 300.)
    @BADNESS_ADJ_RE_NAME 350 /// ^(Web Content|Isolated Web Co|Isolated Servic|file:// Content)$
    @BADNESS_ADJ_RE_NAME 200 /// ^(Privileged Cont|RDD Process|WebExtensions|Utility Process)$

    # --- Tier 2: Regular user GUI applications (baseline in app.slice) ---
    @BADNESS_ADJ_RE_CGROUP_V2 150 /// ^/user\.slice/.*/app\.slice/

    # --- Tier 1: Protected workloads (terminals, dev sessions, coding agents, VMs) ---
    # Note: nohang sums all matching rules across CGROUP_V2/NAME/REALPATH. Keep each
    # Tier 1 workload around -650 total (not <= -1000) so it stays protected below
    # Tiers 2-4 without accidentally becoming Tier 0 (unkillable) if it leaks RAM.
    # Virtual machines (libvirt machine.slice, coding-vm/audit-vm scopes, QEMU/virtiofsd/swtpm)
    @BADNESS_ADJ_RE_CGROUP_V2 -350 /// ^/machine\.slice/
    @BADNESS_ADJ_RE_CGROUP_V2 -350 /// ^/user\.slice/.*/app\.slice/(coding-vm|audit-vm)
    @BADNESS_ADJ_RE_CGROUP_V2 -350 /// ^/system\.slice/(libvirtd|virtqemud)\.service$
    @BADNESS_ADJ_RE_NAME -300 /// ^\.?(qemu-system|virtiofsd|swtpm|virgl_render|libvirtd|virtqemud)

    # Terminals, multiplexers, interactive shells, SSH/Mosh, smartcard/GPG, and coding agents.
    # Matched by process name / binary path (not kitty-*.scope cgroup) so heavy browsers
    # or compilers launched from a terminal are still reclaimed normally in Tiers 3-4.
    @BADNESS_ADJ_RE_NAME -650 /// ^\.?(kitty|kitten|ghostty|konsole|tmux|screen|zsh|ssh|ssh-agent|mosh-client|waypipe|gpg-agent|scdaemon|pinentry)
    @BADNESS_ADJ_RE_NAME -650 /// ^\.?(codex|agy|antigravity|dsh|fx|mcp-nixos|mcp-server-git)
    # Match GUI wrapper/helper binaries (e.g. Electron) of codex-desktop / antigravity-hub
    # without double-stacking onto the `codex` / `agy` CLI binaries already matched by NAME.
    @BADNESS_ADJ_RE_REALPATH -650 /// (-|/)(codex-desktop|antigravity-hub)[^/]*/(?!.*(/codex$|/agy$))

    # --- Tier 0: System & KDE Plasma 6 desktop core (immune) ---
    # Use -1500 so even a Tier 0 service running inside app.slice (base oom_score ~800
    # plus app.slice +150 plus RAM usage) reliably clamps to badness = 0.
    @BADNESS_ADJ_RE_CGROUP_V2 -1500 /// ^/system\.slice/(systemd-|dbus|NetworkManager|wpa_supplicant|tailscaled|sddm|display-manager|polkit|chronyd|veracrypt-hhd|vm-cgroup-nft-sync|nsncd|upower|power-profiles-daemon|accounts-daemon|usbmuxd|pcscd|udisks2|rtkit-daemon|sshd|throne)
    @BADNESS_ADJ_RE_CGROUP_V2 -1500 /// ^/user\.slice/user-[0-9]+\.slice/user@[0-9]+\.service/init\.scope$
    @BADNESS_ADJ_RE_CGROUP_V2 -1500 /// ^/user\.slice/.*/session\.slice/(plasma-|pipewire|wireplumber|dbus|xdg-desktop-portal|xdg-document-portal|xdg-permission-store|at-spi-dbus-bus)
    @BADNESS_ADJ_RE_CGROUP_V2 -1500 /// ^/user\.slice/.*/(app\.slice/(app-throne|app-dbus.*(Fcitx5|kwalletd6|atspi)|sunshine\.service|app-dev\.lizardbyte\.app\.Sunshine|xdg-desktop-portal-gtk\.service)|background\.slice/plasma-(polkit-agent|powerdevil|kglobalaccel|krunner|kactivitymanagerd|gmenudbusmenuproxy|kaccess|knighttimed|ksystemstats|xembedsniproxy))
    @BADNESS_ADJ_RE_NAME -1500 /// ^\.?(kwin_wayland|plasmashell|ksmserver|kded6|startplasma|Xwayland|sddm|dbus-daemon|dbus-broker|pipewire|wireplumber|fcitx5|ksecretd|kwalletd6|Throne|ThroneCore|tailscaled|NetworkManager|wpa_supplicant|nsncd|sshd|mosh-server|veracrypt|sunshine|systemd-logind|systemd)
    @BADNESS_ADJ_RE_REALPATH -1500 /// /bin/\.?(kwin_wayland|plasmashell|ksmserver|kded6|startplasma-wayland|Xwayland|sddm|dbus-daemon|dbus-broker|pipewire|wireplumber|fcitx5|ksecretd|kwalletd6|Throne|ThroneCore|tailscaled|NetworkManager|wpa_supplicant|nsncd|sshd|mosh-server|veracrypt|sunshine)(-wrapped)?$

    # 9. Misc settings
    max_soft_exit_time = 8
    post_kill_exe =
    min_badness = 1
    post_soft_action_delay = 3
    post_zombie_delay = 0.1
    victim_cache_time = 10
    exe_timeout = 20

    # 10. Verbosity, debug, logging
    print_config_at_startup = False
    print_mem_check_results = False
    min_mem_report_interval = 60
    print_proc_table = False
    extra_table_info = None
    print_victim_status = True
    print_victim_cmdline = True
    max_victim_ancestry_depth = 3
    print_statistics = True
    debug_psi = False
    debug_gui_notifications = False
    debug_sleep = False
    debug_threading = False
    separate_log = False
  '';

  nohangConfig = pkgs.runCommand "nohang-rins.conf" {} ''
    cp ${nohangConfigRaw} "$out"
    ${lib.getExe pkgs.nohang} --check --config "$out" >/dev/null
  '';

  # Use raw systemd.user.units drop-ins for Plasma session services so NixOS's
  # systemd.user.services builder does not inject a minimal Environment="PATH=..."
  # that overrides the graphical session PATH (breaking app launches from Plasma).
  mkUserOomDropin = oomScoreAdjust: {
    overrideStrategy = "asDropin";
    text = ''
      [Service]
      OOMScoreAdjust=${toString oomScoreAdjust}
    '';
  };
in {
  # High-priority zstd ZRAM in front of the existing NVMe disk swap partition (prio -1),
  # matching Android's compressed-RAM-first memory management model.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  boot.kernel.sysctl = {
    # Prefer compressing cold anonymous pages into fast ZRAM before evicting active file cache.
    "vm.swappiness" = 100;
    # Single-page swap-in avoids wasted read-ahead overhead on RAM-backed ZRAM.
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

  # Use nohang as the sole userspace OOM handler (avoid conflicting with systemd-oomd).
  systemd.oomd.enable = false;

  services.nohang = {
    enable = true;
    configPath = nohangConfig;
  };

  # Align kernel OOMScoreAdjust on core services so even an instantaneous spike
  # that reaches the kernel OOM killer respects the same protection hierarchy.
  systemd.services = {
    nohang.serviceConfig.OOMScoreAdjust = -1000;
    tailscaled.serviceConfig.OOMScoreAdjust = lib.mkDefault (-900);
    vm-cgroup-nft-sync.serviceConfig.OOMScoreAdjust = lib.mkDefault (-900);
    sshd.serviceConfig.OOMScoreAdjust = lib.mkDefault (-900);
    sddm.serviceConfig.OOMScoreAdjust = lib.mkDefault (-800);
    NetworkManager.serviceConfig.OOMScoreAdjust = lib.mkDefault (-800);
  };

  # `user@.service` runs unprivileged with OOMScoreAdjust = 100 (and default user
  # services inherit +100 -> 200, Chromium renderers 300, kde-baloo 500). Values
  # below 100 are silently clamped to 100 by the kernel without CAP_SYS_RESOURCE,
  # so keep the desktop/audio hierarchy in [100, 200) to get real tiering without
  # lowering user@1000's floor or leaking negative oom_score_adj into app scopes.
  systemd.user.units = {
    "plasma-kwin_wayland.service" = mkUserOomDropin 100;
    "plasma-plasmashell.service" = mkUserOomDropin 120;
    "plasma-ksmserver.service" = mkUserOomDropin 120;
    "plasma-kded6.service" = mkUserOomDropin 150;
  };

  systemd.user.services = {
    dbus-broker = {
      overrideStrategy = "asDropin";
      enableDefaultPath = false;
      serviceConfig.OOMScoreAdjust = 100;
    };
    pipewire = {
      overrideStrategy = "asDropin";
      # Do not replace the session PATH. PipeWire still adds LADSPA_PATH and LV2_PATH.
      enableDefaultPath = false;
      serviceConfig.OOMScoreAdjust = 150;
    };
    pipewire-pulse = {
      overrideStrategy = "asDropin";
      enableDefaultPath = false;
      serviceConfig.OOMScoreAdjust = 150;
    };
    wireplumber = {
      overrideStrategy = "asDropin";
      enableDefaultPath = false;
      serviceConfig.OOMScoreAdjust = 150;
    };
  };
}
