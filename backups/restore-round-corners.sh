#!/usr/bin/env bash
set -euo pipefail

BACKUP="${1:-$HOME/nixos-config/backups/kde/20260616-215726}"
SRC="$BACKUP/config/kwinrc"
DST="$HOME/.config/kwinrc"

if [ ! -f "$SRC" ]; then
  echo "backup kwinrc not found: $SRC" >&2
  exit 1
fi

mkdir -p "$HOME/.config"

if [ -f "$DST" ]; then
  cp -a "$DST" "$DST.before-round-corners-$(date +%Y%m%d-%H%M%S)"
fi

if ! command -v kwriteconfig6 >/dev/null; then
  echo "kwriteconfig6 not found" >&2
  exit 1
fi

python3 - "$SRC" "$DST" <<'PY'
import sys
import subprocess
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

groups_to_restore = {
    "Round-Corners",
    "PrimaryOutline",
    "SecondOutline",
    "Shadow",
    "org.kde.kdecoration2",
}

def parse_kconfig(path):
    data = {}
    current = None

    for raw in path.read_text(errors="replace").splitlines():
        line = raw.strip()

        if not line or line.startswith("#"):
            continue

        if line.startswith("[") and line.endswith("]"):
            current = line[1:-1]
            data.setdefault(current, {})
            continue

        if current is not None and "=" in raw:
            key, value = raw.split("=", 1)
            data[current][key.strip()] = value.strip()

    return data

data = parse_kconfig(src)

def kwrite(group, key, value):
    subprocess.run(
        [
            "kwriteconfig6",
            "--file", str(dst),
            "--group", group,
            "--key", key,
            value,
        ],
        check=True,
    )

for group in groups_to_restore:
    for key, value in data.get(group, {}).items():
        kwrite(group, key, value)

# 强制启用 Rounded Corners / ShapeCorners。多写几个常见 key，无副作用。
for key in [
    "kwin4_effect_shapecornersEnabled",
    "kwin_effect_shapecornersEnabled",
    "shapecornersEnabled",
]:
    kwrite("Plugins", key, "true")
PY

if command -v qdbus6 >/dev/null; then
  qdbus6 org.kde.KWin /KWin reconfigure || true
elif command -v qdbus >/dev/null; then
  qdbus org.kde.KWin /KWin reconfigure || true
fi

echo "round corner settings restored from: $SRC"
