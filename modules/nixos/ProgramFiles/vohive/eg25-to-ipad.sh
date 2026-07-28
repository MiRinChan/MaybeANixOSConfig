set -euo pipefail

eg25-to-mac.sh "$@"

echo
echo "✅ EG25-G 已准备好连接 USB-C iPad"
echo "   1. 从 NixOS 主机拔下模组。"
echo "   2. 用支持数据传输的 USB-C 线直连 iPad。"
echo "   3. 在 iPad「设置 → 通用 → 以太网」确认 ECM 网卡已出现。"
echo "   4. 若设备反复消失或重启，请改用带供电的 USB-C Hub。"
echo
echo "切回 VoHive：把模组接回 NixOS，再运行 eg25-to-vohive.sh。"
