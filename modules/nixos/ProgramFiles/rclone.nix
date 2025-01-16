{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    rclone # rclone
  ];

  # from: https://github.com/TomSnd01/nixos-config/blob/75d3e44448d699d2561e91ffec9dcecc9bc7fc92/modules/rclone-gdrive.nix

  systemd.services.rclone-gdrive = {
    description = "rclone: Mount Google Drive to /home/mirin/.GDrive";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    environment = {
        ALL_PROXY = "socks5://127.0.0.1:2080";
        HTTP_PROXY="http://127.0.0.1:2080";
        HTTPS_PROXY="http://127.0.0.1:2080";
    };

    serviceConfig = {
      Type = "simple";
      User = "mirin";
      Group = "users";
      # Ensure the directory exists before trying to mount
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/mirin/.GDrive";
      # Use the full path for fusermount3
      Environment = "PATH=/run/wrappers/bin:/bin:/usr/bin:${pkgs.coreutils}/bin:${pkgs.fuse}/bin";
      ExecStart = "${pkgs.rclone}/bin/rclone mount GDrive: /home/mirin/.GDrive --config /home/mirin/.config/rclone/rclone.conf  --umask 0000 --default-permissions --allow-non-empty --allow-other --attr-timeout 5m --transfers 4 --buffer-size 32M --low-level-retries 200 --vfs-read-chunk-size 32M --vfs-read-chunk-size-limit 128M --vfs-cache-mode full --vfs-cache-max-age 24h --vfs-cache-max-size 10G";
      # Use the full path for fusermount3
      ExecStop = "/run/wrappers/bin/fusermount3 -u /home/mirin/.GDrive";
    };

    wantedBy = [ "multi-user.target" ];
  };

  environment.etc."fuse.conf".text = ''
    user_allow_other
  '';
}

