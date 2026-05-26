{
  config,
  pkgs,
  lib,
  ...
}: {
  { config, pkgs, lib, ... }:

{
  services.xrdp = {
    enable = true;
    # KDE Plasma 6 (X11) — xrdp 对 Wayland 支持欠佳
    defaultWindowManager = "${pkgs.plasma6.plasma-workspace}/bin/startplasma-x11";
  };
}

  # 防火墙放行 RDP 端口（3389）
  networking.firewall.allowedTCPPorts = [3389];
}
