# KDE 无障碍功能

这里记录本仓库预装的 KDE/桌面无障碍工具，以及之后真正启用时需要做的事。当前配置只把工具装进系统环境，不启用后台服务、不写 Plasma 设置、不加自启动。

## 已预装工具

| 功能 | 包/命令 | 用途 |
| --- | --- | --- |
| 屏幕键盘 | `maliit-keyboard` | Wayland 下的虚拟键盘。 |
| Qt 虚拟键盘插件 | `kdePackages.qtvirtualkeyboard` | 给 Qt/KDE 应用提供虚拟键盘插件。 |
| 屏幕阅读器/讲述人 | `orca` | 读出窗口、控件和文本内容。 |
| 语音调度 | `speechd`, `spd-say` | Orca/KMouth 等工具常用的语音输出层。 |
| 语音合成 | `espeak` | 本地 TTS 引擎，供 Speech Dispatcher 调用。 |
| 放大镜 | `kmag` | KDE 屏幕放大工具。 |
| 输入文字并朗读 | `kmouth` | 输入文本后用语音合成读出来。 |
| 鼠标辅助点击 | `kmousetool` | 鼠标停留后自动点击，减少手动点击。 |
| 特殊字符输入 | `kcharselect` | 选择并复制字体中的特殊字符。 |

KDE 自带的粘滞键、慢速键、按键重复、鼠标键、高对比度、缩放快捷键等仍在“系统设置 -> 无障碍”里配置，不需要额外包。

## 激活屏幕键盘

1. 切到新系统后重新登录 Plasma。
2. 打开“系统设置 -> 键盘 -> 虚拟键盘”。
3. 选择 Maliit/虚拟键盘相关条目。
4. 如果设置页没有出现可选项，先确认命令存在：

```sh
command -v maliit-keyboard
```

也可以直接运行 `maliit-keyboard` 做临时测试。登录界面的屏幕键盘属于 SDDM 配置范围，本次只预装用户会话里的工具。

## 激活屏幕阅读器/讲述人

屏幕阅读器实际使用时建议同时启用 Speech Dispatcher 和 AT-SPI 辅助技术总线。在 NixOS 配置里加入：

```nix
services.speechd.enable = true;
services.gnome.at-spi2-core.enable = true;
```

然后执行系统 rebuild 并重新登录。首次配置可以运行：

```sh
orca --setup
```

日常启动：

```sh
orca
```

语音链路可以用下面命令测试：

```sh
spd-say "hello"
espeak "hello"
```

如果 Orca 报 `org.a11y.Bus` 相关错误，优先检查 `services.gnome.at-spi2-core.enable` 是否已经启用并重新登录。

## 其他工具用法

- `kmag`: 启动 KDE 放大镜；也可以在“系统设置 -> 快捷键”里搜索 KWin 的缩放快捷键。
- `kmouth`: 打开后输入文字并朗读，适合临时文字转语音。
- `kmousetool`: 配置鼠标停留自动点击。
- `kcharselect`: 搜索、复制特殊字符。

## 验证安装

切换到包含本配置的新系统后，可以快速检查：

```sh
command -v maliit-keyboard orca kmag kmouth kmousetool kcharselect spd-say espeak
```
