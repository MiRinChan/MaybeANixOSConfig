# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal NixOS flake configuration. Single host `rins`, single user `mirin`. Directory layout uses Windows-inspired naming (`System32/`, `Users/AppData/`) on top of standard flake structure. Comments mix Chinese and English.

Note from `README.txt`: not everything is declarative — applying this config on a fresh machine **may not** reproduce the live system. Treat the repo as a source of truth for declared state only.

## Build & Apply

```sh
nix fmt                                       # format with alejandra
nixos-rebuild build  --flake .#rins           # build only
sudo nixos-rebuild switch --flake .#rins      # apply system config
home-manager switch  --flake .#mirin          # apply user config (if running standalone)
nix build .#<pkg>                             # build a custom package from ./pkgs
```

Home-manager is wired into the NixOS config (see `flake.nix` `home-manager.users.mirin`), so a `nixos-rebuild switch` normally applies user config too. `home-manager.backupFileExtension = "backup"` is set, so conflicting dotfiles are moved to `*.backup`.

## Architecture

| Path | Role |
|------|------|
| `flake.nix` | Inputs, overlays, single `nixosConfigurations.rins` |
| `System32/configuration.nix` | Boot (lanzaboote), networking + firewall, plasma6/SDDM, flatpak, system-wide systemd tweaks |
| `System32/UsersConf.nix` | `users.users.mirin` (groups, shell) |
| `System32/hardware-configuration.nix` | Generated hardware config |
| `Users/home.nix` | Home-manager entry; declares `username`, default editor/browser/terminal, kdePackages overrides |
| `Users/AppData/` | Per-domain user config (gaming, graphics, git, audio-production, mediaPlayer, …) — imported via `Users/AppData/default.nix` |
| `modules/nixos/` | Reusable NixOS modules — exported via `modules/nixos/default.nix` as `outputs.nixosModules.*` |
| `modules/nixos/ProgramFiles/` | System-wide program bundles (`common.nix`, `steam.nix`, `services.nix`, `virtualMachine.nix`, `openrgb.nix`) |
| `modules/nixos/DRIVER/nvidia.nix` | NVIDIA driver module |
| `modules/home-manager/` | Reusable HM modules (currently empty stub) |
| `overlays/default.nix` | Defines `additions` (custom pkgs), `modifications`, and channel-pinned overlays |
| `pkgs/` | Custom packages — `default.nix` exposes them via `additions` overlay |

### Module wiring

Modules in `modules/nixos/` are listed in `modules/nixos/default.nix`, exported as `outputs.nixosModules.*` from `flake.nix`, then imported in `System32/configuration.nix`. To add a new reusable module: drop the `.nix` file in `modules/nixos/`, register it in `modules/nixos/default.nix`, and import the corresponding `outputs.nixosModules.<name>` in `System32/configuration.nix`.

### Multiple nixpkgs channels

`flake.nix` pins four channels — `master`, `unstable` (the default), `stable` (25.11), and `d209` (specific commit). Overlays in `overlays/default.nix` expose them as `pkgs.master.*`, `pkgs.unstable.*`, `pkgs.stable.*`, `pkgs.d209.*`. Use these when a package is broken/missing on the default channel rather than switching the whole flake.

### Boot & GPU specifics

- Secure Boot via `lanzaboote`; `systemd-boot` is `lib.mkForce false`. Don't re-enable systemd-boot without also disabling lanzaboote.
- `pkiBundle = "/var/lib/sbctl"` — Secure Boot keys live there.
- NVIDIA with kernel modesetting and several `NVreg_*` tuning params; `v4l2loopback` loaded for virtual webcam (`/dev/video9`).
- Kernel is `pkgs.linuxPackages` (LTS) — `_latest`, `_xanmod_stable`, and `linux_zen` are commented alternatives in `configuration.nix`.

### Firewall

`System32/configuration.nix` `networking.firewall` opens specific ports for FTP/FTPS, Sunshine, Wallpaper Engine, and BT. There's also `extraCommands`/`extraStopCommands` carving out `throne-tun` from reverse-path filtering — keep that exception when editing firewall rules.

### Theme

`catppuccin.enable = true` with `flavor = "mocha"`. The catppuccin module is imported at both NixOS and home-manager levels.

## Common Tasks

- **Add a system package**: edit `modules/nixos/ProgramFiles/common.nix`, or add a new file under that directory and import it from `modules/nixos/ProgramFiles/default.nix`.
- **Add a user package/config**: add a `.nix` under `Users/AppData/` and import from `Users/AppData/default.nix`.
- **Add a custom package**: drop `pkgs/<name>.nix`, register it in `pkgs/default.nix`. It becomes available system-wide via the `additions` overlay and buildable with `nix build .#<name>`.
- **Override a kdePackages member**: see the inline overlay in `Users/home.nix` (`signond`, `signon-ui`, `signon-plugin-oauth2`) for the pattern.
- **Pull a package from a different channel**: use `pkgs.master.<name>` / `pkgs.unstable.<name>` / `pkgs.stable.<name>` / `pkgs.d209.<name>` directly in any module.
