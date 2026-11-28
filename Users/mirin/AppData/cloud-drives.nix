{
  config,
  lib,
  pkgs,
  repoRoot,
  ...
}: let
  fusequota = pkgs.callPackage (repoRoot + "/Program Files/Packages/fusequota.nix") {};
  cacheMount = "${config.xdg.cacheHome}/rclone-bounded";
  cacheState = "${config.xdg.stateHome}/rclone-cache";
  backingRoot = "${config.xdg.dataHome}/rclone-mounts";
  fuseEnvironment = "PATH=/run/wrappers/bin:${lib.makeBinPath [pkgs.fuse3]}";
  prepareMount = pkgs.writeShellScript "prepare-cloud-mount" ''
    set -eu
    ${pkgs.coreutils}/bin/mkdir -p "$1"
    if ${pkgs.util-linux}/bin/mountpoint -q "$1"; then
      echo "Mountpoint is already mounted: $1" >&2
      exit 1
    fi
    if [ -n "$(${pkgs.coreutils}/bin/ls -A "$1")" ]; then
      echo "Mountpoint contains local files: $1" >&2
      exit 1
    fi
    ${pkgs.coreutils}/bin/chmod 0700 "$1"
  '';
  holdMount = pkgs.writeShellScript "hold-cloud-mountpoint" ''
    set -eu
    # Keep the underlying directory accessible after mounting over it.
    exec 9< "$1"
    shift
    exec "$@"
  '';
  waitMount = pkgs.writeShellScript "wait-cloud-mount" ''
    set -eu
    for attempt in $(${pkgs.coreutils}/bin/seq 1 120); do
      if ${pkgs.util-linux}/bin/mountpoint -q "$1"; then
        # A disconnected mount must not become an unlimited local directory.
        ${pkgs.coreutils}/bin/chmod 0500 "/proc/$2/fd/9"
        exit 0
      fi
      if ! kill -0 "$2" 2>/dev/null; then
        echo "Mount process ($2) exited before $1 became ready" >&2
        exit 1
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    echo "Mount did not become ready: $1" >&2
    exit 1
  '';
  probeBacking = pkgs.writeShellScript "probe-cloud-backing" ''
    set -eu
    ${pkgs.coreutils}/bin/timeout 15 ${pkgs.coreutils}/bin/ls -A "$1" >/dev/null
  '';
  cleanupMount = pkgs.writeShellScript "cleanup-cloud-mount" ''
    set -eu
    if ${pkgs.util-linux}/bin/findmnt -rn --nocanonicalize --mountpoint "$1" >/dev/null; then
      /run/wrappers/bin/fusermount3 -u "$1"
    fi
    ${pkgs.coreutils}/bin/chmod 0500 "$1"
  '';
  stopMount = pkgs.writeShellScript "stop-cloud-mount" ''
    set -eu
    /run/wrappers/bin/fusermount3 -u "$1"
    # Wait for open backing files and cache writes to close before stopping dependencies.
    if [ -n "''${2:-}" ]; then
      for attempt in $(${pkgs.coreutils}/bin/seq 1 900); do
        if ! kill -0 "$2" 2>/dev/null; then
          exit 0
        fi
        ${pkgs.coreutils}/bin/sleep 0.1
      done
      echo "Mount process did not exit after unmounting: $1" >&2
      exit 1
    fi
  '';
  startCache = pkgs.writeShellScript "start-rclone-cache" ''
    set -eu
    umask 077
    state=${lib.escapeShellArg cacheState}
    image="$state/cache.ext4"
    ${pkgs.coreutils}/bin/mkdir -p "$state"
    if [ ! -e "$image" ]; then
      ${pkgs.coreutils}/bin/truncate -s 32000000000 "$image.new"
      ${pkgs.e2fsprogs}/bin/mkfs.ext4 -q -F -m 0 \
        -E "root_owner=$(${pkgs.coreutils}/bin/id -u):$(${pkgs.coreutils}/bin/id -g)" \
        "$image.new"
      ${pkgs.coreutils}/bin/mv "$image.new" "$image"
    fi
    if [ "$(${pkgs.coreutils}/bin/stat -c %s "$image")" != 32000000000 ]; then
      echo "Cache image must be exactly 32000000000 bytes" >&2
      exit 1
    fi
    # Repair an interrupted cache filesystem without discarding pending uploads.
    status=0
    ${pkgs.e2fsprogs}/bin/e2fsck -p "$image" || status=$?
    if [ "$status" -gt 1 ]; then
      echo "Cache filesystem needs repair (e2fsck status $status)" >&2
      exit "$status"
    fi
    exec ${pkgs.fuse2fs}/bin/fuse2fs -f "$image" ${lib.escapeShellArg cacheMount}
  '';
  drives = {
    gdrive = {
      remote = "gdrive:";
      mount = "${config.home.homeDirectory}/GoogleDrive";
      quota = 2048000000000;
      description = "Google Drive";
    };
    icloud = {
      remote = "icloud:rclone";
      mount = "${config.home.homeDirectory}/.iCloud";
      quota = 256000000000;
      description = "iCloud Drive";
    };
  };
  mkDrive = name: drive: let
    backendName = "rclone-${name}-backend";
    backing = "${backingRoot}/${name}";
  in {
    "${backendName}" = {
      Unit = {
        Description = "Private ${drive.description} backend";
        After = ["rclone-cache.service"];
        Requires = ["rclone-cache.service"];
        BindsTo = ["rclone-cache.service"];
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "notify";
        Environment = fuseEnvironment;
        ExecStartPre = "${prepareMount} ${lib.escapeShellArg backing}";
        ExecStart = lib.escapeShellArgs [
          "${pkgs.rclone}/bin/rclone"
          "mount"
          drive.remote
          backing
          "--config=${config.xdg.configHome}/rclone/rclone.conf"
          "--cache-dir=${cacheMount}/${name}"
          "--vfs-cache-mode=writes"
          # Eviction is a soft target; the shared ext4 image is the hard limit.
          "--vfs-cache-max-size=12G"
          "--vfs-cache-max-age=1h"
          "--dir-cache-time=1m"
          "--umask=077"
        ];
        ExecStop = "${stopMount} ${lib.escapeShellArg backing} $MAINPID";
        ExecStopPost = "${cleanupMount} ${lib.escapeShellArg backing}";
        Restart = "on-failure";
        RestartSec = 30;
        TimeoutStartSec = 120;
        TimeoutStopSec = 120;
        UMask = "0077";
      };
    };
    "rclone-${name}" = {
      Unit = {
        Description = "${drive.description} with ${toString (drive.quota / 1000000000)} GB write quota";
        After = ["${backendName}.service"];
        Requires = ["${backendName}.service"];
        BindsTo = ["${backendName}.service"];
        PartOf = ["${backendName}.service"];
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "exec";
        Environment = fuseEnvironment;
        ExecStartPre = [
          "${prepareMount} ${lib.escapeShellArg drive.mount}"
          "${probeBacking} ${lib.escapeShellArg backing}"
        ];
        # Disable writeback caching so quota failures reach the writing process.
        ExecStart = lib.escapeShellArgs [
          "${holdMount}"
          drive.mount
          "${fusequota}/bin/fusequota"
          "--foreground"
          "--nocache"
          "--quota"
          (toString drive.quota)
          backing
          drive.mount
        ];
        ExecStartPost = "${waitMount} ${lib.escapeShellArg drive.mount} $MAINPID";
        ExecStop = "${stopMount} ${lib.escapeShellArg drive.mount} $MAINPID";
        ExecStopPost = "${cleanupMount} ${lib.escapeShellArg drive.mount}";
        LimitCORE = 0;
        Restart = "on-failure";
        RestartSec = 30;
        TimeoutStartSec = 900;
        TimeoutStopSec = 120;
        UMask = "0077";
      };
    };
  };
in {
  # Trigger cloud mounts asynchronously via a user timer so offline/unproxied
  # boots never block default.target, KDE Plasma startup, or XDG autostart apps.
  systemd.user.targets.rclone-mounts = {
    Unit = {
      Description = "Cloud drive mounts";
      Wants = map (name: "rclone-${name}.service") (builtins.attrNames drives);
    };
  };
  systemd.user.timers.rclone-mounts = {
    Unit.Description = "Start cloud drive mounts asynchronously after login";
    Timer = {
      OnStartupSec = "2s";
      OnActiveSec = "2s";
      Unit = "rclone-mounts.target";
    };
    Install.WantedBy = ["timers.target"];
  };
  systemd.user.services =
    {
      rclone-cache = {
        Unit.Description = "Shared rclone cache with a 32 GB hard limit";
        Service = {
          Type = "exec";
          Environment = fuseEnvironment;
          ExecStartPre = "${prepareMount} ${lib.escapeShellArg cacheMount}";
          ExecStart = "${holdMount} ${lib.escapeShellArg cacheMount} ${startCache}";
          ExecStartPost = "${waitMount} ${lib.escapeShellArg cacheMount} $MAINPID";
          ExecStop = "${stopMount} ${lib.escapeShellArg cacheMount} $MAINPID";
          ExecStopPost = "${cleanupMount} ${lib.escapeShellArg cacheMount}";
          TimeoutStartSec = 180;
          TimeoutStopSec = 120;
          UMask = "0077";
        };
      };
    }
    // lib.foldl' lib.recursiveUpdate {} (lib.mapAttrsToList mkDrive drives);
}
