{
  pkgs,
  config,
  ...
}: {
  # OpenRGB setup
  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };
  environment.systemPackages = [pkgs.i2c-tools];
  users.groups.i2c.members = ["username"]; # create i2c group and add default user to it

  # solaar setup
  services.solaar = {
    enable = true; # Enable the service
    package = pkgs.solaar; # The package to use
    window = "hide"; # Show the window on startup (show, *hide*, only [window only])
    batteryIcons = "regular"; # Which battery icons to use (*regular*, symbolic, solaar)
    extraArgs = ""; # Extra arguments to pass to solaar on startup
  };
}
