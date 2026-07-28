set -euo pipefail

CONNECTION_NAME="eg25-ecm"

if ((EUID != 0)); then
  exec sudo "$0" "$@"
fi

exec 9>/run/lock/eg25-mode-switch.lock
flock -n 9 || {
  echo "另一个 EG25 模式切换正在进行。" >&2
  exit 1
}

echo "[1/5] 断开 ECM 网络..."
if nmcli -t -f NAME connection show | grep -Fxq "$CONNECTION_NAME"; then
  nmcli connection down "$CONNECTION_NAME" 2>/dev/null || true
  nmcli connection delete "$CONNECTION_NAME" 2>/dev/null || true
fi
echo "    ✓ 已断开"

echo '[2/5] 切回 QMI 并软重启模组...'
at_port=/dev/ttyUSB3
if [[ ! -c "$at_port" ]]; then
  at_port=/dev/ttyUSB2
fi
if [[ ! -c "$at_port" ]]; then
  echo "    ✗ 找不到 ECM 模式 AT 端口 /dev/ttyUSB3 或 /dev/ttyUSB2。" >&2
  exit 1
fi
stty -F "$at_port" 115200 raw -echo 2>/dev/null || true
printf 'AT+QCFG="usbnet",0\r' >"$at_port" 2>/dev/null || true
sleep 2

if [[ ! -c /dev/cdc-wdm0 ]]; then
  cfun_sent=false
  for _ in $(seq 1 20); do
    for restart_port in /dev/ttyUSB3 /dev/ttyUSB2; do
      [[ -c "$restart_port" ]] || continue
      stty -F "$restart_port" 115200 raw -echo 2>/dev/null || true
      if printf 'AT+CFUN=1,1\r' >"$restart_port" 2>/dev/null; then
        cfun_sent=true
        break 2
      fi
    done
    sleep 1
  done
  if [[ "$cfun_sent" != true ]]; then
    echo "    ✗ usbnet 已写入，但没有找到可用于软重启的 AT 端口。" >&2
    exit 1
  fi
fi
echo "    ✓ AT 指令已发送，正在重新枚举"

echo "[3/5] 等待模组软重启..."
for _ in $(seq 1 45); do
  [[ -c /dev/cdc-wdm0 && -d /sys/class/net/wwan0 ]] && break
  udevadm settle 2>/dev/null || true
  sleep 1
done
if [[ ! -c /dev/cdc-wdm0 ]]; then
  echo "    ✗ 45 秒内没有发现 /dev/cdc-wdm0。" >&2
  exit 1
fi
echo "    ✓ QMI 控制设备已出现"

echo "[4/5] 启动 VoHive..."
systemctl restart vohive.service

echo "[5/5] 等待 VoHive 就绪..."
for _ in $(seq 1 20); do
  systemctl is-active --quiet vohive.service && break
  sleep 1
done
if ! systemctl is-active --quiet vohive.service; then
  echo "    ✗ VoHive 启动失败，请查看 journalctl -u vohive.service。" >&2
  exit 1
fi

echo
echo "✅ 完成：VoHive 保号模式（QMI）"
echo "   VoHive：active"
echo "   QMI：/dev/cdc-wdm0"
echo "   后台：http://127.0.0.1:7575"
