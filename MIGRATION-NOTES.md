# KDE Plasma Manager Migration Notes

## Backup

Backup directory:

`backups/kde/20260616-215726`

Committed as:

`3d1ae5c backup: capture kde state before plasma migration`

Backup contents:

| Path | Files | Size |
| --- | ---: | ---: |
| `config` | 59 | 288K |
| `local-share/plasma/desktoptheme` | 997 | 16M |
| `local-share/plasma/look-and-feel` | 50 | 11M |
| `local-share/color-schemes` | 6 | 24K |
| `local-share/icons` | 92328 | 618M |
| `local-share/aurorae/themes` | 56 | 1.1M |
| `local-share/wallpapers` | 16 | 15M |
| `local-share/fonts` | 4 | 122M |
| `icons-legacy` | 48 | 3.5M |
| `wallpapers` | 16 | 15M |
| total | 93580 | 799M |

The active wallpaper paths in the rc files also referenced files directly under `~/Pictures`, outside the original backup glob. These were copied into `Users/AppData/assets/wallpapers/` and referenced from `plasma.nix`.

## Theme Audit

Active settings from rc files:

| Setting | Value | Source/action |
| --- | --- | --- |
| Color scheme | `CatppuccinMochaFlamingo` | `catppuccin-kde` exists in nixpkgs; local colors file is also deployed from backup. |
| Widget style | `Klassy` | Existing repo package `pkgs/klassy-qt6`; now owned by `theme-packages.nix`. |
| KWin decoration | `org.kde.klassy` / `Klassy` | Existing repo package `pkgs/klassy-qt6`; decoration rc keys kept in fallback. |
| Plasma desktop theme | `Scratchy` | Local/user asset; deployed from backup via `xdg.dataFile`. |
| Look and feel | `org.kde.breezedark.desktop` | Native Plasma package; declared through `workspace.lookAndFeel`. |
| Icons | `Cobalt-dark` | Local/user asset; deployed from backup via `xdg.dataFile`. |
| Cursor | `WhiteSur-cursors` | `whitesur-cursors` exists in nixpkgs; added to `home.packages`. |
| Splash | empty | Omitted as unset/default. |
| Wallpaper | `/home/mirin/Pictures/v2-76efa32deb7d299c06b3ddf5735f81ac_r.png` | Current active desktop wallpaper uses `org.kde.image`; copied to `Users/AppData/assets/wallpapers/` and referenced from `plasma.nix`. |

Local themes deployed by `theme-packages.nix`:

- Plasma themes: `Frosted`, `Moe`, `Moe-Dark`, `Scratchy`, `Windows-Beuty`, `Windows-Beuty-Dark`, `Windows-Eleven`, `Windows-Eleven-Dark`
- Look-and-feel themes: `Moe`, `Scratchy`, `windows-eleven`, `windows-eleven-Dark`, `windows.eleven.Dark.P6`
- Aurorae themes: `Moe`, `MoeDark`, `Scratchy`, `Windows-Eleven-Dark`, `irixium`
- Color schemes: `AbsoluteDark`, `CatppuccinMochaFlamingo`, `Moe`, `MoeDark`, `PlasmaOverdose`, `Scratchy`
- Icon themes: `Cobalt`, `Cobalt-dark`, `Colloid*`, `Eleven*`, `Irixium`, `Windows-*`, `klassy*`
- Wallpapers and local fonts from the backup

Package audit notes:

- Confirmed through NixOS MCP before the external usage limit was hit: `klassy`, `catppuccin-kde`, `whitesur-cursors`, and `plasma-overdose-kde-theme` exist in nixpkgs unstable.
- After the external usage limit was hit, further remote package lookups were not retried. Remaining local themes are treated as local/user assets.
- `pkgs.wallpaper-engine-kde-plugin` is still exposed and buildable, but it is no longer installed by this migration because the current active wallpaper is a static image.

## Native Mappings

The main module is `Users/AppData/plasma.nix`.

Mapped to high-level plasma-manager options:

- `programs.plasma.workspace`: Plasma theme, color scheme, look-and-feel, icon theme, cursor, static image wallpaper.
- `programs.plasma.panels`: bottom and top panels, Kickoff, spacer, system tray, weather tray config, margin separator, digital clock, task manager, show desktop.
- `programs.plasma.desktop`: folder-view icon alignment/sorting and mouse actions.
- `programs.plasma.kwin`: blur, dim admin mode, magic-lamp minimize, shake cursor, translucency, glide open/close, night light, virtual desktops, and base tiling layout.
- `programs.plasma.shortcuts`: meaningful non-default global shortcuts from `kglobalshortcutsrc`.
- `programs.plasma.krunner.shortcuts`: KRunner launch shortcut.
- `programs.plasma.kscreenlocker.appearance`: lock-screen image wallpaper.
- `programs.plasma.spectacle.shortcuts`: Spectacle launch/fullscreen/rectangular-region shortcuts.
- `programs.plasma.input.keyboard.layouts`: `us`.
- `programs.plasma.fonts`: general, fixed-width, menu, small, toolbar, and window-title fonts.
- `programs.kate`: Kate font, indentation line visibility, and bracket flash setting.

Note: current plasma-manager trunk exposes app modules as `programs.kate`, `programs.konsole`, and `programs.okular`, not `programs.plasma.apps.*`.

## Fallback Settings

Fallback `programs.plasma.configFile` is used where there is no native option or the native option would change semantics:

- `kdeglobals`: accent color, terminal app/service, Xft hinting/subpixel, Klassy widget style, file dialog behavior, KScreen scale, remote preview limits.
- `kwinrc`: Klassy decoration keys, HDR/XWayland/Wayland input-method settings, screen edge binding, third-party effects, round-corners plugin settings, translucency strength, blur-plus settings, outline/shadow plugin settings.
- `kcminputrc`: keyboard repeat disabled and generic X11 libinput flat acceleration flag.
- `kscreenlockerrc`: image fallback for the lock screen, while the active custom plugin is native.
- `plasma-localerc`: locale format.
- `plasmarc`: recently used wallpaper paths.
- `kactivitymanagerdrc`: activity UUID display name.
- `katerc`: Kate settings not covered by the native module, plus Kate color theme because the native theme option forces `Auto Color Theme Selection=false` while the original rc had it true.

## Omitted Or Partial

- `rc2nix` baseline was not generated. `nix run github:nix-community/plasma-manager -- rc2nix` first failed on sandbox access to `/home/mirin/.cache/nix`, and the required escalation was rejected by the external usage limit. No workaround was attempted.
- Generated/update-only rc state was omitted: `plasmashellrc [Updates]`, empty `ksmserverrc` saved-session counts, empty `ksplashrc` theme, `konsolerc` with only `ConfigVersion` and blank UI color scheme.
- Desktop widget geometries in `plasma-org.kde.plasma.desktop-appletsrc` referenced applet IDs without complete matching applet sections in the captured file; these were not migrated.
- Per-output/per-screen KWin tiling groups were simplified to the common 25/50/25 horizontal layout plus padding through native `kwin.tiling`.
- `ScreenMapping` desktop item placement was not migrated; it is volatile desktop icon state.
- No window rules were migrated because no `kwinrulesrc` was present in the backup.

## Validation Status

Completed:

- `nix-instantiate --parse Users/AppData/plasma.nix`
- `nix-instantiate --parse Users/AppData/theme-packages.nix`
- `nix-instantiate --parse flake.nix`
- `alejandra --check Users/AppData/plasma.nix Users/AppData/theme-packages.nix Users/AppData/default.nix Users/AppData/common.nix pkgs/default.nix flake.nix`
- `nix fmt -- flake.nix pkgs/default.nix Users/AppData/default.nix Users/AppData/common.nix Users/AppData/theme-packages.nix Users/AppData/plasma.nix`
- `nix fmt -- pkgs/wallpaper-engine-kde-plugin/default.nix`
- `nix flake lock` updated `flake.lock` with `plasma-manager` at `a524a6160e6df89f7673ba293cf7d78b559eb1a5`.
- `nix eval .#homeConfigurations.mirin.activationPackage.drvPath`
- `nix build .#wallpaper-engine-kde-plugin --no-link`
- `nix build .#homeConfigurations.mirin.activationPackage --no-link`
- `nixos-rebuild build --flake .#rins`

Note: bare `nix fmt` currently invokes the raw Alejandra formatter without path arguments in this flake and fails by trying to format empty stdin. The explicit `nix fmt -- <paths>` invocations above use the same flake formatter with concrete paths.

Recommended apply command:

```sh
home-manager switch --flake .#mirin -b backup
```

Keep `programs.plasma.overrideConfig = false` through the first applied run. Only enable it after visually verifying the session, panels, wallpaper plugins, shortcuts, lock screen, and Kate behavior.
