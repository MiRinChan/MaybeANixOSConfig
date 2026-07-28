set -euo pipefail

CONFIG_FILE="/var/lib/vohive/config/config.yaml"

usage() {
  echo "用法：eg25-set-imei.sh <15位IMEI>" >&2
}

valid_imei() {
  local imei="$1"
  local i sum=0 digit doubled

  [[ "$imei" =~ ^[0-9]{15}$ ]] || return 1
  for ((i = 0; i < 14; i++)); do
    digit=$((10#${imei:i:1}))
    if ((i % 2 == 1)); then
      doubled=$((digit * 2))
      ((doubled > 9)) && doubled=$((doubled - 9))
      sum=$((sum + doubled))
    else
      sum=$((sum + digit))
    fi
  done
  digit=$((10#${imei:14:1}))
  (((sum + digit) % 10 == 0))
}

if (($# != 1)); then
  usage
  exit 2
fi
TARGET_IMEI="$1"
if ! valid_imei "$TARGET_IMEI"; then
  echo "IMEI 必须是通过 Luhn 校验的 15 位数字。" >&2
  exit 2
fi

if ((EUID != 0)); then
  exec sudo "$0" "$@"
fi

exec 9>/run/lock/eg25-mode-switch.lock
flock -n 9 || {
  echo "另一个 EG25 模式切换或维护操作正在进行。" >&2
  exit 1
}

vohive_was_active=false
if systemctl is-active --quiet vohive.service; then
  vohive_was_active=true
  systemctl stop vohive.service
fi
restore_service() {
  if [[ "$vohive_was_active" == true ]]; then
    systemctl start vohive.service
  fi
}
trap restore_service EXIT

send_on_port() {
  local port="$1"
  local modem_command="$2"
  printf '%s\r' "$modem_command" |
    timeout 8 socat - "$port,crnl" 2>/dev/null || true
}

find_at_port() {
  local port response
  for port in /dev/ttyUSB2 /dev/ttyUSB3 /dev/ttyUSB1; do
    [[ -c "$port" ]] || continue
    response="$(send_on_port "$port" 'AT')"
    if grep -Eq '(^|[[:space:]])OK([[:space:]]|$)' <<<"$response"; then
      echo "$port"
      return 0
    fi
  done
  return 1
}

AT_PORT="$(find_at_port || true)"
if [[ -z "$AT_PORT" ]]; then
  echo "没有找到可响应 AT 命令的 EG25 串口。" >&2
  exit 1
fi

imei_field_count="$(
  { grep -Eo "modem_imei[[:space:]]*:[[:space:]]*['\"]?[0-9]{15}['\"]?" "$CONFIG_FILE" || true; } |
    wc -l
)"
if [[ "$imei_field_count" != 1 ]]; then
  echo "预期 $CONFIG_FILE 中恰好有一个 modem_imei，实际为 $imei_field_count；拒绝写入。" >&2
  exit 1
fi

capability_response="$(send_on_port "$AT_PORT" 'AT+EGMR=?')"
if ! grep -Eq '\+EGMR:.*\(0,1\).*\([^)]*7' <<<"$capability_response"; then
  echo "当前固件未声明 EGMR 写模式的 IMEI 字段 7。" >&2
  exit 1
fi

current_response="$(send_on_port "$AT_PORT" 'AT+EGMR=0,7')"
current_imei="$(grep -Eo '[0-9]{15}' <<<"$current_response" | head -n1 || true)"
if [[ ! "$current_imei" =~ ^[0-9]{15}$ ]]; then
  echo "无法读取当前 IMEI，拒绝写入。" >&2
  exit 1
fi

config_backup="${CONFIG_FILE}.before-imei-$(date +%Y%m%d-%H%M%S)"
cp -a "$CONFIG_FILE" "$config_backup"

if [[ "$current_imei" != "$TARGET_IMEI" ]]; then
  write_response="$(send_on_port "$AT_PORT" "AT+EGMR=1,7,\"${TARGET_IMEI}\"")"
  if ! grep -Eq '(^|[[:space:]])OK([[:space:]]|$)' <<<"$write_response"; then
    echo "EGMR 写入命令被固件拒绝；配置未修改，备份位于 $config_backup。" >&2
    exit 1
  fi
fi

verify_response="$(send_on_port "$AT_PORT" 'AT+EGMR=0,7')"
if ! grep -q "$TARGET_IMEI" <<<"$verify_response"; then
  echo "写入后的即时回读不匹配；配置未修改，备份位于 $config_backup。" >&2
  exit 1
fi
echo "✓ 即时回读匹配 $TARGET_IMEI"

config_temp="$(mktemp "${CONFIG_FILE}.tmp.XXXXXX")"
sed -E \
  "s/(modem_imei[[:space:]]*:[[:space:]]*)['\"]?[0-9]{15}['\"]?/\1\"${TARGET_IMEI}\"/" \
  "$CONFIG_FILE" >"$config_temp"
if [[ "$(grep -o "$TARGET_IMEI" "$config_temp" | wc -l)" != 1 ]]; then
  echo "无法只更新一个 VoHive IMEI 锚点；保留原配置。" >&2
  exit 1
fi
chown --reference="$CONFIG_FILE" "$config_temp"
chmod --reference="$CONFIG_FILE" "$config_temp"
mv "$config_temp" "$CONFIG_FILE"
echo "✓ VoHive 配置已更新；原配置备份：$config_backup"

send_on_port "$AT_PORT" 'AT+CFUN=1,1' >/dev/null
sleep 5

persistent_match=false
for _ in $(seq 1 90); do
  AT_PORT="$(find_at_port || true)"
  if [[ -n "$AT_PORT" ]]; then
    persistent_response="$(send_on_port "$AT_PORT" 'AT+EGMR=0,7')"
    if grep -q "$TARGET_IMEI" <<<"$persistent_response"; then
      persistent_match=true
      break
    fi
  fi
  sleep 1
done
if [[ "$persistent_match" != true ]]; then
  echo "模组重启后未能回读目标 IMEI；VoHive 配置备份位于 $config_backup。" >&2
  exit 1
fi
echo "✓ 重启后持久化回读匹配 $TARGET_IMEI"

restore_service
trap - EXIT
if [[ "$vohive_was_active" == true ]]; then
  systemctl is-active --quiet vohive.service
  echo "✓ vohive.service 已恢复"
else
  echo "✓ vohive.service 原本未运行，保持停止状态"
fi
