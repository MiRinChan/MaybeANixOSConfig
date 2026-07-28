{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.vohive;

  initialConfig = pkgs.writeText "vohive-config.yaml" ''
    server:
      debug: false
      port: "${cfg.listenAddress}:${toString cfg.port}"

    web:
      username: admin
      password: admin

    devices: []

    vowifi:
      enabled: false

    webhook:
      enabled: false
  '';

  djiEg25Provision = pkgs.writeShellApplication {
    name = "dji-eg25-provision";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      kmod
      socat
      systemd
      usbutils
    ];
    text = ''
      set -euo pipefail
      shopt -s nullglob

      mode="inspect"
      case "''${1:-}" in
        "")
          ;;
        --apply)
          mode="quectel"
          ;;
        --restore-dji)
          mode="dji"
          ;;
        -h|--help)
          cat <<'USAGE'
      Usage:
        dji-eg25-provision                 Inspect and save the current modem USB configuration
        dji-eg25-provision --apply         Permanently change 2ca3:4006 to Quectel 2c7c:0125
        dji-eg25-provision --restore-dji   Permanently restore 2c7c:0125 to DJI 2ca3:4006

      The permanent modes modify modem NV storage and reboot the modem. Stop
      vohive.service before restoring a modem that is already in use.
      USAGE
          exit 0
          ;;
        *)
          echo "Unknown argument: $1" >&2
          exit 2
          ;;
      esac

      if (( EUID != 0 )); then
        echo "This command must run as root." >&2
        exit 1
      fi

      if systemctl is-active --quiet vohive.service; then
        echo "vohive.service is active; stop it before accessing the AT port." >&2
        exit 1
      fi

      find_devices() {
        local vendor="$1"
        local product="$2"
        local sysdev
        for sysdev in /sys/bus/usb/devices/*; do
          [[ -r "$sysdev/idVendor" && -r "$sysdev/idProduct" ]] || continue
          [[ "$(<"$sysdev/idVendor")" == "$vendor" ]] || continue
          [[ "$(<"$sysdev/idProduct")" == "$product" ]] || continue
          printf '%s\n' "$sysdev"
        done
      }

      mapfile -t dji_devices < <(find_devices 2ca3 4006)
      mapfile -t quectel_devices < <(find_devices 2c7c 0125)
      device_count=$(( ''${#dji_devices[@]} + ''${#quectel_devices[@]} ))
      if (( device_count == 0 )); then
        echo "No DJI 2ca3:4006 or Quectel 2c7c:0125 modem was found." >&2
        exit 1
      fi
      if (( device_count > 1 )); then
        echo "More than one matching modem is connected; refusing an ambiguous operation." >&2
        exit 1
      fi

      current_id="2ca3:4006"
      if (( ''${#quectel_devices[@]} == 1 )); then
        current_id="2c7c:0125"
      fi
      echo "Detected modem USB identity: $current_id"

      modprobe option
      if [[ "$current_id" == "2ca3:4006" ]]; then
        new_id=/sys/bus/usb-serial/drivers/option1/new_id
        if [[ ! -w "$new_id" ]]; then
          echo "option driver new_id is unavailable: $new_id" >&2
          exit 1
        fi
        printf '%s\n' "2ca3 4006" >"$new_id"
        udevadm settle
        sleep 2
      fi

      send_at() {
        local port="$1"
        local command="$2"
        printf '%s\n' "$command" |
          timeout 8 socat - "$port,crnl" 2>/dev/null || true
      }

      # DJI's firmware identifies itself as Baiwang QDC507 rather than EG25-G.
      # Its documented AT control interface is the third option port.
      at_port=/dev/ttyUSB2
      if [[ ! -c "$at_port" ]]; then
        echo "The expected AT control port is missing: $at_port" >&2
        exit 1
      fi
      response="$(send_at "$at_port" "ATI")"
      model="$(send_at "$at_port" "AT+GMM")"
      identity="$response"$'\n'"$model"
      if ! grep -Eqi 'Baiwang|QDC507|Quectel|EG25|EC25' <<<"$identity"; then
        echo "The device on $at_port did not identify as a supported modem:" >&2
        printf '%s\n' "$identity" >&2
        exit 1
      fi
      echo "Verified DJI/Quectel control port: $at_port"

      usb_config="$(send_at "$at_port" 'AT+QCFG="usbcfg"')"
      usbnet_config="$(send_at "$at_port" 'AT+QCFG="usbnet"')"
      if ! grep -q '+QCFG:' <<<"$usb_config"; then
        echo "The modem did not return its USB configuration; refusing to continue." >&2
        exit 1
      fi

      install -d -m 0700 ${lib.escapeShellArg "${cfg.dataDir}/provisioning"}
      record=${lib.escapeShellArg "${cfg.dataDir}/provisioning"}/"$(date -u +%Y%m%dT%H%M%SZ)-usb-config.txt"
      {
        printf 'usb_identity=%s\n' "$current_id"
        printf 'at_port=%s\n' "$at_port"
        printf '%s\n' "$identity"
        printf '%s\n' "$usb_config"
        printf '%s\n' "$usbnet_config"
      } >"$record"
      chmod 0600 "$record"
      echo "Saved the pre-change modem configuration to $record"

      if [[ "$mode" == "inspect" ]]; then
        echo "Inspection complete; no modem NV setting was changed."
        exit 0
      fi

      target_id="2c7c:0125"
      qcfg='AT+QCFG="usbcfg",0x2C7C,0x0125,1,1,1,1,1,0,0'
      if [[ "$mode" == "dji" ]]; then
        target_id="2ca3:4006"
        qcfg='AT+QCFG="usbcfg",0x2CA3,0x4006,1,1,1,1,1,0,0'
      fi
      if [[ "$current_id" == "$target_id" ]]; then
        echo "The modem already uses $target_id; nothing to change."
        exit 0
      fi

      result="$(send_at "$at_port" "$qcfg")"
      if ! grep -q 'OK' <<<"$result"; then
        echo "The permanent USB configuration command was not acknowledged:" >&2
        printf '%s\n' "$result" >&2
        exit 1
      fi
      echo "Permanent USB configuration accepted; rebooting the modem."
      send_at "$at_port" 'AT+CFUN=1,1' >/dev/null

      expected_vendor="2c7c"
      expected_product="0125"
      if [[ "$mode" == "dji" ]]; then
        expected_vendor="2ca3"
        expected_product="4006"
      fi
      for _ in $(seq 1 30); do
        if [[ -n "$(find_devices "$expected_vendor" "$expected_product")" ]]; then
          udevadm settle
          echo "Verified the modem re-enumerated as $target_id."
          exit 0
        fi
        sleep 1
      done

      echo "The modem did not re-enumerate as $target_id within 30 seconds." >&2
      exit 1
    '';
  };

  eg25Status = pkgs.writeShellApplication {
    name = "eg25-status.sh";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      iproute2
      systemd
    ];
    text = builtins.readFile ./vohive/eg25-status.sh;
  };

  eg25SetIMEI = pkgs.writeShellApplication {
    name = "eg25-set-imei.sh";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      gnused
      socat
      sudo
      systemd
      util-linux
    ];
    text = builtins.readFile ./vohive/eg25-set-imei.sh;
  };

  eg25ToMac = pkgs.writeShellApplication {
    name = "eg25-to-mac.sh";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      iproute2
      networkmanager
      sudo
      systemd
      util-linux
    ];
    text = builtins.readFile ./vohive/eg25-to-mac.sh;
  };

  eg25ToIPad = pkgs.writeShellApplication {
    name = "eg25-to-ipad.sh";
    runtimeInputs = [
      eg25ToMac
    ];
    text = builtins.readFile ./vohive/eg25-to-ipad.sh;
  };

  eg25ToVohive = pkgs.writeShellApplication {
    name = "eg25-to-vohive.sh";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      networkmanager
      sudo
      systemd
      util-linux
    ];
    text = builtins.readFile ./vohive/eg25-to-vohive.sh;
  };
in {
  options.services.vohive = {
    enable = lib.mkEnableOption "VoHive modem management";

    package = lib.mkPackageOption pkgs "vohive-next" {};

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/vohive";
      description = "Writable VoHive configuration, database, and log directory.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address used by the VoHive HTTP server.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 7575;
      description = "Port used by the VoHive HTTP server.";
    };
  };

  config = lib.mkMerge [
    {
      services.vohive.enable = lib.mkDefault true;
    }
    (lib.mkIf cfg.enable {
      boot.kernelModules = [
        "option"
        "qmi_wwan"
      ];

      networking.modemmanager.enable = false;

      environment.systemPackages = [
        djiEg25Provision
        eg25SetIMEI
        eg25Status
        eg25ToMac
        eg25ToIPad
        eg25ToVohive
        pkgs.socat
        pkgs.usbutils
      ];

      services.udev.extraRules = ''
        # VoHive owns QMI, while NetworkManager may manage the modem in ECM mode.
        ACTION=="add", SUBSYSTEM=="net", DRIVERS=="qmi_wwan", ATTRS{idVendor}=="2c7c", ATTRS{idProduct}=="0125", ENV{NM_UNMANAGED}="1"
      '';

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0700 root root -"
        "d ${cfg.dataDir}/config 0700 root root -"
        "d ${cfg.dataDir}/data 0700 root root -"
        "d ${cfg.dataDir}/logs 0700 root root -"
        "d ${cfg.dataDir}/provisioning 0700 root root -"
      ];

      systemd.services.vohive = {
        description = "VoHive Qualcomm modem management";
        wantedBy = ["multi-user.target"];
        after = [
          "network.target"
          "systemd-udev-settle.service"
        ];
        wants = ["systemd-udev-settle.service"];

        path = with pkgs; [
          alsa-utils
          iproute2
          libmbim
          libqmi
          psmisc
          systemd
        ];

        preStart = ''
          install -d -m 0700 \
            ${lib.escapeShellArg cfg.dataDir} \
            ${lib.escapeShellArg "${cfg.dataDir}/config"} \
            ${lib.escapeShellArg "${cfg.dataDir}/data"} \
            ${lib.escapeShellArg "${cfg.dataDir}/logs"}
          if [[ ! -e ${lib.escapeShellArg "${cfg.dataDir}/config/config.yaml"} ]]; then
            install -m 0600 ${initialConfig} ${lib.escapeShellArg "${cfg.dataDir}/config/config.yaml"}
          fi
        '';

        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe cfg.package} -c ${cfg.dataDir}/config/config.yaml";
          WorkingDirectory = cfg.dataDir;
          User = "root";
          Group = "root";
          Restart = "on-failure";
          RestartSec = "5s";

          AmbientCapabilities = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
            "CAP_NET_RAW"
          ];
          CapabilityBoundingSet = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
            "CAP_NET_RAW"
          ];
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = false;
          PrivateTmp = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "full";
          ReadWritePaths = [cfg.dataDir];
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
            "AF_UNIX"
          ];
          RestrictRealtime = true;
        };
      };
    })
  ];
}
