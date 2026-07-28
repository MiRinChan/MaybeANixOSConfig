set -u

VIDPID="2c7c:0125"

find_modem_net() {
  local expected_driver="$1"
  local net_path properties
  for net_path in /sys/class/net/*; do
    properties="$(udevadm info --query=property --path="$net_path" 2>/dev/null)" || continue
    grep -qx 'ID_VENDOR_ID=2c7c' <<<"$properties" || continue
    grep -qx 'ID_MODEL_ID=0125' <<<"$properties" || continue
    grep -Eq "^ID_NET_DRIVER=($expected_driver)$" <<<"$properties" || continue
    basename "$net_path"
  done
}

usb_count=0
for vendor_file in /sys/bus/usb/devices/*/idVendor; do
  usb_device="${vendor_file%/idVendor}"
  [[ "$(<"$vendor_file")" == "2c7c" ]] || continue
  [[ -r "$usb_device/idProduct" && "$(<"$usb_device/idProduct")" == "0125" ]] || continue
  ((usb_count += 1))
done

qmi_iface="$(find_modem_net qmi_wwan | head -n1)"
ecm_iface="$(find_modem_net 'cdc_ether|cdc_ncm' | head -n1)"

echo "=== NixOS 侧 ==="
echo "  USB 模组 $VIDPID：$usb_count 处"
echo "  VoHive 服务：$(systemctl is-active vohive.service 2>/dev/null || true)"
echo "  QMI 控制设备：$([[ -c /dev/cdc-wdm0 ]] && echo '/dev/cdc-wdm0（存在）' || echo '无')"
echo "  QMI 网卡：${qmi_iface:-无}"

if [[ -n "$ecm_iface" ]]; then
  ecm_ipv4="$(ip -4 -o address show dev "$ecm_iface" scope global 2>/dev/null | tr -s ' ' | cut -d' ' -f4 | paste -sd, -)"
  echo "  ECM 网卡：$ecm_iface（IPv4：${ecm_ipv4:-尚未获取}）"
else
  echo "  ECM 网卡：无"
fi

echo
echo "=== 当前模式判断 ==="
if [[ -n "$ecm_iface" ]]; then
  echo "  → NixOS 上网模式（ECM）"
elif [[ -n "$qmi_iface" && -c /dev/cdc-wdm0 ]]; then
  echo "  → VoHive 保号模式（QMI）"
elif ((usb_count > 0)); then
  echo "  → 模组已连接，但数据接口尚未完成枚举"
else
  echo "  → 未检测到模组"
fi
