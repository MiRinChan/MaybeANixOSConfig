{
  config,
  lib,
  pkgs,
  ...
}: {
  # Add sunshine to make my pad could connect to my computer. For entertament.
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };
}
