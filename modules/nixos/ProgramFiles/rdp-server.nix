{
  config,
  pkgs,
  lib,
  ...
}: {
  # 启用 KDE 远程桌面（RDP）
  services.kde.remote-desktop = {
    enable = true;
    # 可选：允许未加密连接（局域网内推荐）
    # allowUnencrypted = true;
  };

  # 防火墙放行 RDP 端口（3389）
  networking.firewall.allowedTCPPorts = [3389];
}
