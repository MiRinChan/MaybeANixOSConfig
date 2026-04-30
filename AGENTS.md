# Agent Instructions — NixOS Configuration

## Overview

Personal NixOS flake configuration for host `rins`, user `mirin`. Uses a Windows-inspired directory naming convention.

## Architecture

| Directory | Role |
|-----------|------|
| `System32/` | System-level NixOS config (boot, networking, services) |
| `Users/` | User-level home-manager config (`home.nix` entry, `AppData/` per-app modules) |
| `modules/nixos/` | Reusable NixOS modules (drivers, programs, sound, locale) |
| `modules/home-manager/` | Reusable home-manager modules (fonts) |
| `overlays/` | Package overlays and patches |
| `pkgs/` | Custom package definitions |
| `flake.nix` | Flake entry point — defines inputs, outputs, single host config |

## Key Conventions

- **Language**: Nix (flakes). Formatter: `alejandra`.
- **Single host**: `rins`. Single user: `mirin`.
- **Module pattern**: Modules in `modules/` export via `default.nix` and are consumed as `outputs.nixosModules.*` or `outputs.homeManagerModules.*`.
- **Multiple nixpkgs channels**: `master`, `unstable` (default), `stable`, `d209` — accessed via overlays (`pkgs.master.*`, `pkgs.unstable.*`, `pkgs.stable.*`).
- **Secure Boot**: Uses `lanzaboote`; systemd-boot is force-disabled.
- **GPU**: NVIDIA with kernel modesetting and power management.
- **Theme**: Catppuccin Mocha applied globally.
- **Comments**: Mix of Chinese and English.

## Build & Test

```sh
# Format
nix fmt

# Build system config (dry run)
nixos-rebuild build --flake .#rins

# Apply system config
sudo nixos-rebuild switch --flake .#rins

# Apply home-manager config
home-manager switch --flake .#mirin
```

## Common Tasks

- **Add a system package**: Edit `modules/nixos/ProgramFiles/common.nix` or create a new file in that directory and import it from `default.nix`.
- **Add a user package/config**: Create a file in `Users/AppData/` and import from `Users/AppData/default.nix`.
- **Add a custom package**: Create `pkgs/<name>.nix`, add to `pkgs/default.nix`.
- **Add an overlay**: Edit `overlays/default.nix`.
