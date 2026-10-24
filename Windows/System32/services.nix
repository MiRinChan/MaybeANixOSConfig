{
  config,
  lib,
  pkgs,
  ...
}: let
  maintenanceWithoutStoreVM = pkgs.writeShellScript "maintenance-without-store-vm" ''
    # GC removes store paths. Optimisation replaces inodes used by guest overlays.
    if ${pkgs.procps}/bin/pgrep -f '^([^ ]*/)?virtiofsd .*--shared-dir(=| )/nix/store/?( |$)' >/dev/null \
      || ${pkgs.procps}/bin/pgrep -f '^[^ ]*qemu-system[^ ]* .*path=/nix/store([, ]|$)' >/dev/null; then
      echo "Skip store maintenance: a VM shares the host /nix/store."
      exit 1
    fi
  '';
in {
  # Bound the file indexer and its extractors without changing KDE settings.
  systemd.user.services.kde-baloo = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      MemoryHigh = "1G";
      MemoryMax = "2G";
      MemorySwapMax = "1G";
      OOMScoreAdjust = 500;
    };
  };

  systemd.services.nh-clean = lib.mkIf config.programs.nh.clean.enable {
    serviceConfig.ExecCondition = maintenanceWithoutStoreVM;
  };
  systemd.services.nix-gc = lib.mkIf config.nix.gc.automatic {
    serviceConfig.ExecCondition = maintenanceWithoutStoreVM;
  };
  systemd.services.nix-optimise = lib.mkIf config.nix.optimise.automatic {
    serviceConfig.ExecCondition = maintenanceWithoutStoreVM;
  };

  # Supply the hard limit used by the VM's transient user service after login.
  # Apply to the current manager with prlimit, without restarting the session.
  systemd.services."user@1000" = {
    overrideStrategy = "asDropin";
    restartIfChanged = false;
    stopIfChanged = false;
    serviceConfig.LimitNOFILE = 2097152;
  };

  # Flatpak
  services.flatpak.enable = true;
  services.flatpak.remotes = [
    {
      name = "flathub-beta";
      location = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
    }
    {
      name = "flathub";
      location = "https://dl.flathub.org/repo/";
    }
  ];
  # services.flatpak.update.onActivation = true;
  services.flatpak.overrides = {
    global = {
      # Force Wayland by default
      Context.sockets = ["wayland" "!x11" "!fallback-x11"];

      Context.filesystems = [
        "$HOME/.local/share/fonts:ro"
        "$HOME/.icons:ro"
        "/nix/store:ro"
        "xdg-config/fontconfig:ro"
      ];

      Environment = {
        # Fix un-themed cursor in some Wayland apps
        XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";

        # Force correct theme for some GTK apps
        GTK_THEME = "Adwaita:dark";
      };
    };
  };

  systemd.services.flatpak-managed-install = {
    # Run managed Flatpak installs after DNS/network has settled.
    after = ["NetworkManager.service" "network-online.target"];
    wants = ["network-online.target"];
  };

  services.udev.extraRules = ''
    # WebHID / hidraw
    SUBSYSTEM=="hidraw", MODE="0660", TAG+="uaccess"
  '';
}
