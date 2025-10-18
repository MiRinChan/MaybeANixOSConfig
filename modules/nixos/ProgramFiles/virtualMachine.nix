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

  # provide docker container
  environment.systemPackages = with pkgs; [
    docker-compose # provide docker-compose command
    winboat # provide winboat for managing windows containers
  ];
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  virtualisation.docker.storageDriver = "btrfs";
}
