{
  config,
  pkgs,
  lib,
  ...
}: {
  # Wayland VNC 服务器
  services.wayvnc = {
    enable = true;
    # 局域网内可放行端口
    openFirewall = true;
  };

  # 防火墙放行 VNC 端口（5900）
  networking.firewall.allowedTCPPorts = [5900];
}
