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

find_ecm_iface() {
  local net_path properties
  for net_path in /sys/class/net/*; do
    properties="$(udevadm info --query=property --path="$net_path" 2>/dev/null)" || continue
    grep -qx 'ID_VENDOR_ID=2c7c' <<<"$properties" || continue
    grep -qx 'ID_MODEL_ID=0125' <<<"$properties" || continue
    grep -Eq '^ID_NET_DRIVER=(cdc_ether|cdc_ncm)$' <<<"$properties" || continue
    basename "$net_path"
  done
}

echo "[1/4] 停止 VoHive，释放模组..."
systemctl stop vohive.service || true
echo "    ✓ 已停止"

echo '[2/4] 切换到 ECM 并软重启模组...'
if [[ ! -c /dev/ttyUSB2 ]]; then
  echo "    ✗ 找不到 QMI 模式 AT 端口 /dev/ttyUSB2。" >&2
  exit 1
fi
stty -F /dev/ttyUSB2 115200 raw -echo 2>/dev/null || true
# DJI firmware may tear down the USB endpoint before write(2) returns even
# though the complete command was accepted. Target-interface detection below
# is authoritative, so an EIO here is expected and non-fatal.
printf 'AT+QCFG="usbnet",1\r' >/dev/ttyUSB2 2>/dev/null || true
sleep 2

# Stock Quectel firmware needs CFUN after changing usbnet. The DJI firmware may
# briefly re-enumerate as soon as QCFG is written, so wait for an AT port instead
# of assuming the old ttyUSB2 node remains writable.
if [[ -z "$(find_ecm_iface | head -n1)" ]]; then
  cfun_sent=false
  for _ in $(seq 1 20); do
    for at_port in /dev/ttyUSB3 /dev/ttyUSB2; do
      [[ -c "$at_port" ]] || continue
      stty -F "$at_port" 115200 raw -echo 2>/dev/null || true
      if printf 'AT+CFUN=1,1\r' >"$at_port" 2>/dev/null; then
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

echo "[3/4] 等待模组软重启并枚举 ECM 网卡..."
ecm_iface=""
for _ in $(seq 1 30); do
  udevadm settle 2>/dev/null || true
  ecm_iface="$(find_ecm_iface | head -n1)"
  [[ -n "$ecm_iface" ]] && break
  sleep 1
done
if [[ -z "$ecm_iface" ]]; then
  echo "    ✗ 30 秒内没有发现 Quectel ECM 网卡。" >&2
  exit 1
fi
echo "    ✓ ECM 网卡：$ecm_iface"

echo "[4/4] 让 NetworkManager 获取地址并设为默认出口..."
nmcli device set "$ecm_iface" managed yes
if nmcli -t -f NAME connection show | grep -Fxq "$CONNECTION_NAME"; then
  nmcli connection modify "$CONNECTION_NAME" \
    connection.interface-name "$ecm_iface" \
    connection.autoconnect yes \
    ipv4.method auto ipv4.never-default no ipv4.route-metric 10 \
    ipv6.method auto ipv6.never-default no ipv6.route-metric 10
else
  nmcli connection add \
    type ethernet \
    ifname "$ecm_iface" \
    con-name "$CONNECTION_NAME" \
    connection.autoconnect yes \
    ipv4.method auto ipv4.never-default no ipv4.route-metric 10 \
    ipv6.method auto ipv6.never-default no ipv6.route-metric 10
fi
nmcli connection up "$CONNECTION_NAME" ifname "$ecm_iface"

ipv4=""
for _ in $(seq 1 20); do
  ipv4="$(ip -4 -o address show dev "$ecm_iface" scope global 2>/dev/null | tr -s ' ' | cut -d' ' -f4 | head -n1)"
  [[ -n "$ipv4" ]] && break
  sleep 1
done

if [[ -n "$ipv4" ]]; then
  echo
  echo "✅ 完成：NixOS 上网模式（ECM）"
  echo "   网卡 $ecm_iface，IP $ipv4"
  echo "   提示：用完后运行 eg25-to-vohive.sh 切回保号模式。"
else
  echo
  echo "❌ ECM 网卡没有取得 IPv4 地址。请检查 SIM、APN、CFUN 和流量套餐。" >&2
  exit 1
fi
