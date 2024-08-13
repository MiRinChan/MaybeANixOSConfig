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
  environment.systemPackages = [ pkgs.i2c-tools ];
  users.groups.i2c.members = [ "username" ]; # create i2c group and add default user to it
}
