# Agent Instructions — NixOS Configuration

## Overview

Personal NixOS flake configuration for host `rins`, user `mirin`. Directory layout uses Windows-inspired names (`System32/`, `Users/AppData/`) on top of standard flake structure. Comments mix Chinese and English. Single host, single user — don't generalize for multi-host setups unless asked.

Per `README.txt`: not everything is declarative — the repo is authoritative for declared state only.

## Build, Apply, Format

```sh
nix fmt                                       # alejandra — required style
nixos-rebuild build  --flake .#rins           # build without activating
sudo nixos-rebuild switch --flake .#rins      # apply system config
home-manager switch --flake .#mirin -b backup # apply user config
nix build .#<name>                            # build a custom package from ./pkgs
```

`nh` equivalents:

```sh
nh os switch --ask --hostname rins ~/nixos-config
nh home switch --ask --configuration mirin --backup-extension backup ~/nixos-config
```

Home-manager is intentionally separate from the NixOS rebuild. Run `nixos-rebuild` for system config and `home-manager switch` for user config. Use `-b backup` with standalone Home Manager so conflicting dotfiles get renamed to `*.backup`.

## File Map

| Path | Role |
|------|------|
| `flake.nix` | Inputs, overlays, `nixosConfigurations.rins`, `homeConfigurations.mirin` |
| `flake.lock` | Pinned inputs — commit when running `nix flake update` |
| `System32/configuration.nix` | Boot (lanzaboote), networking + firewall, plasma6/SDDM, flatpak, systemd tweaks, nix settings |
| `System32/UsersConf.nix` | `users.users.mirin` (groups: wheel/adbusers/docker/uinput/video/render; shell zsh) |
| `System32/hardware-configuration.nix` | Generated — generally don't hand-edit |
| `Users/home.nix` | Home-manager entry: username, default editor/browser/terminal, inline `kdePackages` overlay |
| `Users/AppData/` | Per-domain user config; aggregated by `Users/AppData/default.nix` |
| `modules/nixos/` | Reusable NixOS modules; index in `modules/nixos/default.nix` |
| `modules/nixos/ProgramFiles/` | System-installed program bundles (`common.nix`, `steam.nix`, `services.nix`, `virtualMachine.nix`, `openrgb.nix`) |
| `modules/nixos/DRIVER/nvidia.nix` | NVIDIA driver module |
| `modules/home-manager/` | Reusable HM modules (currently an empty stub) |
| `overlays/default.nix` | `additions` (custom pkgs), `modifications` (patches), `master-/unstable-/stable-/d209-packages` (channel exposers) |
| `pkgs/` | Custom packages; `pkgs/default.nix` exposes them via the `additions` overlay |
| `pkgs/credit.txt` | Attribution notes for community-derived packages |

## Module Wiring

Modules in `modules/nixos/` are not auto-discovered. To add one:

1. Create `modules/nixos/<name>.nix`.
2. Register in `modules/nixos/default.nix` (e.g. `myThing = import ./MyThing.nix;`).
3. Import in `System32/configuration.nix` as `outputs.nixosModules.<key>`.

For files under `modules/nixos/ProgramFiles/`, only step 1 plus a line in `modules/nixos/ProgramFiles/default.nix` is needed — the parent module is already imported.

User-level modules under `Users/AppData/` only need to be listed in `Users/AppData/default.nix`.

## Multiple nixpkgs Channels

`flake.nix` pins four channels; overlays expose them as attributes:

| Input | Use |
|-------|-----|
| `nixpkgs` (= `nixpkgs-unstable`) | Default; what unqualified `pkgs.foo` resolves to |
| `nixpkgs-master` | `pkgs.master.foo` |
| `nixpkgs-stable` (25.11) | `pkgs.stable.foo` |
| `nixpkgs-d209` (frozen commit `d209d80…`) | `pkgs.d209.foo` |

Reach for a non-default channel when a package is broken on unstable rather than switching the whole flake. `config.allowUnfree = true`.

## Boot / GPU / Hardware Specifics

- **Secure Boot** via `lanzaboote`; `systemd-boot` is `lib.mkForce false`. Don't re-enable systemd-boot without disabling lanzaboote — they conflict.
- Secure Boot PKI bundle: `/var/lib/sbctl`. `sbctl` CLI is installed.
- **NVIDIA** with kernel modesetting + tuning flags (`NVreg_PreserveVideoMemoryAllocations`, `NVreg_UsePageAttributeTable`, `NVreg_EnablePCIeGen3`, …) in `boot.kernelParams`.
- **Virtual webcam**: `v4l2loopback` loaded as `/dev/video9` with label `虚拟摄像头`.
- **Kernel**: `pkgs.linuxPackages` (LTS). `_latest`, `_xanmod_stable`, `linux_zen` are commented alternatives.
- `boot.supportedFilesystems = ["ntfs"]`.

## Networking / Firewall

`networking.firewall` opens specific TCP/UDP ports for FTP/FTPS, Sunshine, Wallpaper Engine, BT, Mosh. There's a reverse-path-filtering carve-out for the `throne-tun` interface via `extraCommands`/`extraStopCommands` — **preserve this** when editing firewall rules.

`systemd.network.wait-online` is disabled to avoid boot delays.

## Theming

`catppuccin.enable = true; catppuccin.flavor = "mocha"`. Module is imported at both NixOS and home-manager levels. `NIXOS_OZONE_WL = "1"` pushes Electron/Chrome onto Wayland.

## Common Tasks

| Goal | Where to edit |
|------|---------------|
| Add a system-wide package | `modules/nixos/ProgramFiles/common.nix` (append to `environment.systemPackages`) |
| Add a user-only package | `Users/AppData/common.nix` or a relevant per-domain file under `Users/AppData/` |
| Add a custom-built package | `pkgs/<name>.nix` + register in `pkgs/default.nix`; becomes `pkgs.<name>` and `nix build .#<name>` |
| Patch an upstream package | Add an entry under `modifications` in `overlays/default.nix` |
| Pin from a different channel | Reference `pkgs.master.<name>` / `pkgs.stable.<name>` / `pkgs.d209.<name>` directly |
| Override a `kdePackages` member | See the inline overlay in `Users/home.nix` (`signond`, `signon-ui`, `signon-plugin-oauth2`) |
| Open a firewall port | `networking.firewall.allowedTCPPorts` / `allowedUDPPorts` / `allowedUDPPortRanges` |
| Update pinned inputs | `nix flake update` (commit `flake.lock`) |

## Before reporting done

1. `nix fmt`
2. `nixos-rebuild build --flake .#rins` clean
3. If you touched the bootloader, double-check no `lib.mkForce` collision
4. If you touched the firewall, the `throne-tun` carve-out is intact
5. If you touched inputs, `flake.lock` is committed
