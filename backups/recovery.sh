BACKUP="$HOME/nixos-config/backups/kde/20260616-215726"
SAVE="$HOME/kde-before-restore-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$SAVE"

# # 先备份当前状态
# rsync -a "$HOME/.config/" "$SAVE/config/"
# rsync -a "$HOME/.local/share/" "$SAVE/local-share/"

# 关闭会写配置的 KDE 程序
kquitapp6 plasmashell 2>/dev/null || true
pkill dolphin 2>/dev/null || true

# 只覆盖备份里存在的文件
rsync -a "$BACKUP/config/" "$HOME/.config/"
rsync -a "$BACKUP/local-share/" "$HOME/.local/share/"

# 旧图标目录也只覆盖，不删除
if [ -d "$BACKUP/icons-legacy" ]; then
  mkdir -p "$HOME/.icons"
  rsync -a "$BACKUP/icons-legacy/" "$HOME/.icons/"
fi

kbuildsycoca6 --noincremental
systemctl --user restart plasma-plasmashell.service
qdbus org.kde.KWin /KWin reconfigure
