{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  # provide QEMU/KVM virtual machines with virt-manager as the GUI frontend.
  # 用户需要加入 libvirtd 组才能免 sudo 管理虚拟机（见 Windows/System32/accounts.nix）。
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # 软件 TPM，Windows 11 客户机需要
      vhostUserPackages = [pkgs.virtiofsd];
      verbatimConfig = ''
        namespaces = []

        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/userfaultfd",
          "/dev/kvm", "/dev/net/tun",
          "/dev/dri/card1", "/dev/dri/renderD128",
          "/dev/nvidia0", "/dev/nvidiactl", "/dev/nvidia-modeset",
          "/dev/nvidia-uvm", "/dev/nvidia-uvm-tools"
        ]
      '';
    };
  };
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true; # 从 SPICE 查看器透传 USB 设备

  # provide docker container
  environment.systemPackages = with pkgs; [
    docker-compose # provide docker-compose command
    inputs.winapps.packages.${stdenv.hostPlatform.system}.winapps
    # winboat # provide winboat for managing windows containers
  ];
  nix.settings = {
    substituters = ["https://winapps.cachix.org/"];
    trusted-public-keys = ["winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="];
  };
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  virtualisation.docker.storageDriver = "btrfs";
}
