{ config, pkgs, lib, ... }:

{
  # 安装 wayvnc 包
  environment.systemPackages = [ pkgs.wayvnc ];

  # 用户级 systemd 服务：开机自启 wayvnc
  systemd.user.services.wayvnc = {
    description = "Wayland VNC Server";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc";
      Restart = "on-failure";
    };
  };

  # 只允许 Tailscale 接口访问 VNC（更安全）
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 5900 ];
  };
}
}
