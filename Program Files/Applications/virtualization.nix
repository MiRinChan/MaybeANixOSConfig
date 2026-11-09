{
  inputs,
  pkgs,
  repoRoot,
  ...
}: let
  win11Virt = repoRoot + "/Program Files/Packages/win11-virt";
  virtManagerScaledCommand = "${pkgs.coreutils}/bin/env GDK_BACKEND=x11 GDK_SCALE=1 GDK_DPI_SCALE=1 ${pkgs.virt-manager}/bin/virt-manager --connect qemu:///system";
  virtManagerScaled = pkgs.makeDesktopItem {
    name = "virt-manager-scaled";
    desktopName = "Virtual Machine Manager (Scale Fix)";
    comment = "Manage virtual machines with the corrected window scale";
    icon = "virt-manager";
    exec = virtManagerScaledCommand;
    tryExec = "${pkgs.virt-manager}/bin/virt-manager";
    terminal = false;
    dbusActivatable = false;
    startupNotify = false;
    startupWMClass = ".virt-manager-wrapped";
    categories = ["System" "Emulator" "GTK"];
    keywords = ["virt-manager" "virtualization" "libvirt" "qemu" "Windows 11" "缩放"];
    extraConfig = {
      "Name[zh_CN]" = "虚拟系统管理器（缩放修正）";
      "Comment[zh_CN]" = "使用已验证的窗口缩放设置管理虚拟机";
    };
    actions.Windows11 = {
      name = "打开Windows 11控制台";
      exec = "${virtManagerScaledCommand} --show-domain-console f43b44d6-6c21-4f3a-bb63-48da581b7994";
    };
  };
  win11WifiBypass = pkgs.writeText "win11-wifi-direct.nft" ''
    add table inet win11_wifi_direct
    add chain inet win11_wifi_direct prerouting { type filter hook prerouting priority -151; policy accept; }
    flush chain inet win11_wifi_direct prerouting
    add rule inet win11_wifi_direct prerouting iifname "virbr-win11" ip saddr 192.168.123.11 counter meta mark set 0x2024 ct mark set 0x2024 comment "Windows 11 Wi-Fi direct"
  '';
  win11WifiHook = pkgs.writeShellScript "win11-wifi-network-hook" ''
    set -eu
    [ "''${1:-}" = win11-wifi ] || exit 0
    iptables=${pkgs.iptables}/bin/iptables
    nft=${pkgs.nftables}/bin/nft
    rule=(-i wlp0s20f3 -m conntrack --ctstate ESTABLISHED,RELATED --ctdir REPLY --ctorigsrc 192.168.123.0/24 -j RETURN)
    case "''${2:-}" in
      started|reconnect|updated|port-created)
        "$iptables" -w -t mangle -C nixos-fw-rpfilter "''${rule[@]}" 2>/dev/null ||
          "$iptables" -w -t mangle -I nixos-fw-rpfilter 1 "''${rule[@]}"
        "$nft" -f ${win11WifiBypass}
        ;;
      stopped)
        "$iptables" -w -t mangle -D nixos-fw-rpfilter "''${rule[@]}" 2>/dev/null || true
        "$nft" delete table inet win11_wifi_direct 2>/dev/null || true
        ;;
    esac
  '';
  # Keep the Windows 11 emulator and renderer behind generation-stable
  # /run/current-system paths. The libvirt XML no longer stores /nix/store
  # paths, so a rebuild or GC does not require redefining the domain.
  win11Qemu = pkgs.callPackage (win11Virt + "/qemu.nix") {};
  win11QemuPat = pkgs.callPackage (win11Virt + "/qemu-pat.nix") {
    qemu = win11Qemu;
  };
  win11Virgl = pkgs.callPackage (win11Virt + "/virglrenderer.nix") {};
  win11VirglGtk = pkgs.callPackage (win11Virt + "/virglrenderer-gtk.nix") {
    virglrenderer = win11Virgl;
  };
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
    virtManagerScaled
    win11QemuPat
    docker-compose # provide docker-compose command
    inputs.winapps.packages.${stdenv.hostPlatform.system}.winapps
    # winboat # provide winboat for managing windows containers
  ];
  environment.etc = {
    "win11/libvirglrenderer.so.1".source = "${win11Virgl}/lib/libvirglrenderer.so.1";
    "win11/libvirglrenderer-gtk.so.1".source = "${win11VirglGtk}/lib/libvirglrenderer.so.1";
  };
  nix.settings = {
    substituters = ["https://winapps.cachix.org/"];
    trusted-public-keys = ["winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="];
  };
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    storageDriver = "btrfs";
  };
}
