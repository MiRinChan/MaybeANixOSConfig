{
  config,
  lib,
  pkgs,
  ...
}: {
  # provide virtual machine
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = ["user-with-access-to-virtualbox"];
  virtualisation.virtualbox.host.enableExtensionPack = true;
}
