{
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
