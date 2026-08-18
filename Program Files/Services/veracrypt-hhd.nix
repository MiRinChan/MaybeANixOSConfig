{
  config,
  pkgs,
  ...
}: let
  # Stable whole-disk path for the WD Blue HDD (currently /dev/sda).
  # If this disk is ever replaced, regenerate with:
  #   readlink -f /dev/disk/by-id/* | grep sda  (or ls -l /dev/disk/by-id/)
  device = "/dev/disk/by-id/ata-WDC_WD10EZEX-08WN4A0_WD-WCC6Y2SSVPCH";
  # systemd-escape --path --suffix=device "$device"
  deviceUnit = "dev-disk-by\\x2did-ata\\x2dWDC_WD10EZEX\\x2d08WN4A0_WD\\x2dWCC6Y2SSVPCH.device";
  mountPoint = "/home/mirin/.HHD";
  # Keyfile is a sops-nix binary secret decrypted to /run/secrets before this service starts.
  keyfile = config.sops.secrets.veracrypt-hhd-keyfile.path;
  veracrypt = "${pkgs.d209.veracrypt}/bin/veracrypt";
in {
  # Create the mountpoint (owned by mirin) so the mounted volume stays accessible.
  systemd.tmpfiles.rules = [
    "d ${mountPoint} 0755 mirin users - -"
  ];

  systemd.services.veracrypt-hhd = {
    description = "Mount VeraCrypt-protected HHD at ${mountPoint}";
    # Wait for the sops keyfile to be decrypted and for the disk node to exist.
    after = ["local-fs.target" "sops-install-secrets.service" deviceUnit];
    requires = ["sops-install-secrets.service" deviceUnit];
    wantedBy = ["multi-user.target"];

    # VeraCrypt shells out to dmsetup/mount/fusermount/modprobe at runtime;
    # the default unit PATH only has coreutils/findutils/grep/sed/systemd.
    path = [pkgs.lvm2 pkgs.util-linux pkgs.kmod pkgs.fuse3 pkgs.fuse];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Bound the stop timeout so a stuck VeraCrypt core-service cannot hang
      # shutdown.  (Best-effort dismount already ran in ExecStop.)
      TimeoutStopSec = "30s";
      # Mount in text/non-interactive mode. The volume has no password, only
      # the keyfile, so --password= supplies the empty password explicitly.
      ExecStart = [
        "${pkgs.coreutils}/bin/install -d -o mirin -g users -m 0755 ${mountPoint}"
        "${veracrypt} --text --non-interactive --mount --keyfiles=${keyfile} --password= ${device} ${mountPoint}"
      ];
      # Best-effort dismount on stop/rebuild/shutdown. Leading '-' ignores
      # failure when the volume was already manually dismounted.
      ExecStop = "-${veracrypt} --text --dismount ${mountPoint}";
      TimeoutStartSec = "2min";
    };
  };
}
