{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  win11WifiHook = pkgs.writeShellScript "win11-wifi-network-hook" ''
    set -eu
    [ "''${1:-}" = win11-wifi ] || exit 0
    iptables=${pkgs.iptables}/bin/iptables
    rule=(-i wlp0s20f3 -m conntrack --ctstate ESTABLISHED,RELATED --ctdir REPLY --ctorigsrc 192.168.123.0/24 -j RETURN)
    case "''${2:-}" in
      started|reconnect|updated|port-created)
        "$iptables" -w -t mangle -C nixos-fw-rpfilter "''${rule[@]}" 2>/dev/null ||
          "$iptables" -w -t mangle -I nixos-fw-rpfilter 1 "''${rule[@]}"
        ;;
      stopped)
        "$iptables" -w -t mangle -D nixos-fw-rpfilter "''${rule[@]}" 2>/dev/null || true
        ;;
    esac
  '';
in {
  # provide QEMU/KVM virtual machines with virt-manager as the GUI frontend.
  # 用户需要加入 libvirtd 组才能免 sudo 管理虚拟机（见 Windows/System32/accounts.nix）。
  virtualisation.libvirtd = {
    enable = true;
    hooks.network.win11-wifi = win11WifiHook;
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
  networking.firewall = {
    extraCommands = "${win11WifiHook} win11-wifi started begin";
    extraStopCommands = "${win11WifiHook} win11-wifi stopped end";
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
