{
  config,
  lib,
  pkgs,
  inputs,
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

  programs.throne = {
    enable = true;
    tunMode.enable = true;
    # tunMode.setuid = true;
    # package = pkgs.stable.throne;
  };

  services.tailscale.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [config.services.tailscale.interfaceName];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [config.services.tailscale.port];
  };

  systemd.services.tailscaled.postStart = ''
    for i in $(${pkgs.coreutils}/bin/seq 1 30); do
      if ${pkgs.iptables}/bin/iptables -S ts-input >/dev/null 2>&1; then
        ${pkgs.iptables}/bin/iptables -C ts-input -i lo -s 100.64.0.0/10 -j ACCEPT 2>/dev/null || \
        ${pkgs.iptables}/bin/iptables -I ts-input 1 -i lo -s 100.64.0.0/10 -j ACCEPT || true
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.2
    done
    exit 0
  '';

  # Tailscale traffic must bypass Throne/sing-box interception:
  # - Mark 100.64.0.0/10 (incl. MagicDNS 100.100.100.100) and the tailnet ULA
  #   fd7a:115c:a1e0::/48 with sing-box's own bypass mark 0x2024 before its
  #   hooks (redirect/mark/queue) run, so Throne leaves them alone.
  # - Pin the CGNAT range to tailscale0 as a fallback so a peer without a /32
  #   in table 52 can never fall into Throne's catch-all table 2022.
  systemd.services.tailscale-priority = {
    description = "Route Tailscale traffic directly, bypassing Throne TUN";
    after = ["tailscaled.service"];
    requires = ["tailscaled.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.nftables pkgs.iproute2];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      nft delete table inet ts-priority 2>/dev/null || true
      nft -f - <<'NFT'
      table inet ts-priority {
        chain output_pre {
          type filter hook output priority mangle - 2; policy accept;
          meta nfproto ipv4 ip daddr 100.64.0.0/10 meta mark set 0x00002024 ct mark set 0x00002024
          meta nfproto ipv6 ip6 daddr fd7a:115c:a1e0::/48 meta mark set 0x00002024 ct mark set 0x00002024
        }
      }
      NFT
      ip route replace 100.64.0.0/10 dev tailscale0 proto static metric 1000
    '';
  };

  # Note: https://www.tomoliver.net/posts/using-an-slr-as-a-webcam-nixos
}
