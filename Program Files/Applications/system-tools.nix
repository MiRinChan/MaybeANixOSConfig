{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    msedit # MS-DOS Editor
    screen # Screen
    kdePackages.ksvg # Require by SDDM
    alejandra # Code formater
    catppuccin # Prettier system color
    plymouth # Prettier startup
    eza # Prettier ls
    kdePackages.kgpg # kGpg
    kdePackages.kleopatra # kleopatra
    flatpak-builder # Flatpak builder
    appstream # Software metadata handling library, proride CLI
    (easyeffects.overrideAttrs (oldAttrs: {
      preFixup = let
        lv2Plugins = [
          calf
          zam-plugins
          lsp-plugins
          x42-plugins
        ];
      in
        (oldAttrs.preFixup or "")
        + ''
          gappsWrapperArgs+=(
            --set LV2_PATH "${lib.makeSearchPath "lib/lv2" lv2Plugins}"
          )
        '';
    }))
    qpwgraph # Graphic PipeWire Configer
    alsa-utils # provide CLI
    devenv # provide code envireoment
    kdePackages.filelight # Quickly visualize your disk space usage
    # KDE/desktop accessibility tools. Installed only; services and autostart stay manual.
    maliit-keyboard # Wayland virtual keyboard
    kdePackages.qtvirtualkeyboard # Qt virtual keyboard plugin
    orca # Screen reader
    speechd # Speech Dispatcher
    espeak # Speech synthesizer
    kdePackages.kmag # Screen magnifier
    kdePackages.kmouth # Type-and-say front end for speech synthesizers
    kdePackages.kmousetool # Automatic mouse click helper
    kdePackages.kcharselect # Special character selector
    gparted # provide a gui for parted
    pkgs.sbctl # For debugging and troubleshooting Secure Boot.
    libarchive # provide bsdcat bsdcpio bsdtar bsdunzip
    jq # provide a json proceessor
    qemu # qemu
    klassy-qt6 # KWin decoration/style plugin must be visible to the Plasma session.
    pkgs.kde-rounded-corners # Rounded
    ntfs3g # NTFS
    ffmpeg
    gphoto2
    mpv
    kdePackages.kdecoration
    cmake
    gcc
    gdb
    nh # seem also programs.nh
    nur.repos.linyinfeng.easylpac
    lpac
    android-tools
    papirus-icon-theme
    kdePackages.breeze-icons
    adwaita-icon-theme
    iloader
    waypipe
    tmux
    bun
    libnotify
    git # ComfyUI and custom node source updates
    aria2 # Resumable model downloads
    uv # Isolated Python environment management for ComfyUI
  ];

  programs.zsh.enable = true;

  programs.ssh.startAgent = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false; # 关掉这里的 SSH 支持
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 30d --keep 10";
    flake = "/home/mirin/nixos-config"; # sets NH_OS_FLAKE variable for you
  };

  # Note: https://www.tomoliver.net/posts/using-an-slr-as-a-webcam-nixos
}
