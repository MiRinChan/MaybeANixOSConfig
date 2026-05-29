{
  config,
  lib,
  pkgs,
  ...
}: {
  # provide virtual machine
  users.extraGroups.vboxusers.members = ["user-with-access-to-virtualbox"];

  virtualisation.virtualbox = {
    host = {
      enable = true;
      enableExtensionPack = true;
      enableKvm = true;
      addNetworkInterface = false;
      package = pkgs.stable.virtualbox;
    };
  };

  # provide QEMU/KVM virtual machines with virt-manager as the GUI frontend.
  # 用户需要加入 libvirtd 组才能免 sudo 管理虚拟机（见 System32/UsersConf.nix）。
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # 软件 TPM，Windows 11 客户机需要
      ovmf = {
        enable = true;
        packages = [pkgs.OVMFFull.fd]; # UEFI 固件 + Secure Boot 支持
      };
    };
  };
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true; # 从 SPICE 查看器透传 USB 设备

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
