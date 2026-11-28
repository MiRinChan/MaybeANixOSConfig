# Agent Instructions — NixOS Configuration (`rins` / `mirin`)

## Scope & Design Principles

This repository declares NixOS host `rins` (`x86_64-linux`) and the standalone
Home Manager configuration for user `mirin`.

- **Layout & language**: Uses Windows-inspired top-level directory names
  (`Windows/`, `Program Files/`, `ProgramData/`, `Users/mirin/`) and a mix of
  Chinese and English comments. Keep the single-host, single-user architecture
  unless explicitly asked to generalize it.
- **Explicit module graph**: Do not reintroduce `modules/nixos`,
  `modules/home-manager`, root `pkgs`, or root `overlays` abstractions. All
  imports are explicit.
- **Declared vs. live state**: This repository is authoritative only for
  declared configuration. Do not assume it captures every piece of live machine
  state, KDE Plasma state, or mutable local tool state (such as `~/.codex` or
  `~/.gemini`).
- **Path handling**: Quote shell paths that contain spaces (for example
  `"Program Files/default.nix"`) and compose Nix paths from `repoRoot` (for
  example `repoRoot + "/Program Files"`).

## Environment & Tooling

Before running commands that depend on project inputs, inspect `flake.nix`,
`flake.lock`, this file, and the target modules. Read-only Git and file
inspection commands may run directly.

- **MCP integration**: `mcp-nixos` (`nixos` MCP server) is configured for Codex
  (`/etc/codex/config.toml` and `programs.mcp`) as well as `agy` and Antigravity
  (`~/.gemini/config/mcp_config.json`, kept updated via Home Manager
  activation). Use `mcp-nixos` to query upstream NixOS/Home Manager options and
  package metadata, and verify final behavior against this repository's pinned
  `flake.lock` and overlays.
- **Evaluation, formatting, and validation builds**:

```sh
nix fmt -- path/to/changed.nix
deadnix --fail --exclude Windows/System32/hardware-configuration.nix -- .
nix flake show
nix flake check
nix eval .#nixosConfigurations.rins.config.system.build.toplevel.drvPath
nixos-rebuild build --flake .#rins
nix eval .#homeConfigurations.mirin.activationPackage.drvPath
nix build .#homeConfigurations.mirin.activationPackage --no-link
nix build .#<package> --no-link
```

- **Build-only rule**: `nixos-rebuild build` and Home Manager builds are
  validation only. **Never** run `nixos-rebuild switch`, `nh os switch`, or
  `home-manager switch` unless the user explicitly asks. Home Manager is
  standalone and is **not** activated by a NixOS system rebuild.

## Directory Responsibilities

| Path | Responsibility |
| --- | --- |
| `flake.nix` | Flake inputs, `packages`/`overlays`/`formatter`/`checks` outputs, and `rins` + `mirin` entrypoints |
| `Program Files/default.nix` | Aggregation of system-level application and service modules |
| `Program Files/Applications/` | System apps and runtimes: Codex system/udev/nix-ld glue (`codex.nix`), FHS + `nix-ld` (`fhs.nix`), OpenRGB + Solaar (`openrgb.nix`), Steam + Gamescope + CUDA Sunshine (`steam.nix`), CLI/desktop/accessibility tools + `nh`/GPG/SSH (`system-tools.nix`), and QEMU/KVM + custom Win11 virgl/PAT + rootless Btrfs Docker + WinApps (`virtualization.nix`) |
| `Program Files/Services/` | System services and routing: Mosh/usbmuxd/pcscd/udisks2 (`device-integration.nix`), Throne TUN + Tailscale + NTP Wi-Fi + VM cgroup kill-switch routing (`network-routing.nix`), and VeraCrypt HDD auto-mount at `/home/mirin/.HHD` (`veracrypt-hhd.nix`) |
| `Program Files/Scripts/` | Service scripts and unit tests (`vm-cgroup-nft-sync.py`, `test-vm-cgroup-nft-sync.py`) |
| `Program Files/Packages/` | Public custom derivations (`gallant-terminal-nerd`, `openai-sans`, `scrcpy3`, `tsuyaku`, `dsh`) plus internal packages and patches (`signon-plugin-oauth2`, `signon-ui`, `iloader-client-info.patch`, `win11-virt/`) |
| `Program Files/Overlays/` | Public overlays (`additions`, `llm-agents`, `modifications`, `master-packages`, `unstable-packages`, `stable-packages`, `d209-packages`, `cached-librewolf`) |
| `ProgramData/SOPS/` | Encrypted SOPS secret documents (`system.json` for host root secrets, `mirin.yaml` for user secrets); never plaintext or empty placeholders |
| `Windows/System32/default.nix` | NixOS system module aggregation only |
| `Windows/System32/configuration.nix` | System overlays, Catppuccin Mocha, and `system.stateVersion` (`24.05`) |
| `Windows/System32/boot.nix` | `linux_xanmod_latest` kernel, Lanzaboote Secure Boot (`/var/lib/sbctl`), EFI, Plymouth, `v4l2loopback`, and kernel parameters |
| `Windows/System32/networking.nix` | Hostname `rins`, NetworkManager, non-flushing `nftables`, firewall ports, `virbr0` trust, `throne-tun` RPF rule, and disabled `wait-online` |
| `Windows/System32/nix.nix` | Nix daemon resource caps, `max-jobs = 1` / `cores = 8`, `ccache`, pinned registries/`nixPath`, substituters, and store optimisation |
| `Windows/System32/desktop.nix` | KDE Plasma 6, SDDM Wayland, `NIXOS_OZONE_WL = "1"`, XDG portals, and `dconf` |
| `Windows/System32/services.nix` | Flatpak Wayland overrides, `kde-baloo` memory cap, VM-shared `/nix/store` GC/optimise guard, `user@1000` `LimitNOFILE`, and WebHID udev rules |
| `Windows/System32/accounts.nix` | `mirin` user account, supplementary groups, zsh login shell, and Steam scaling env |
| `Windows/System32/authentication.nix` | Initrd FIDO2 LUKS unlock (`cryptroot`) and PAM U2F (`kde`, `sudo`, `login`) |
| `Windows/System32/audio.nix` | PipeWire (up to 384 kHz), WirePlumber (`MOONDROP Dawn Pro` USB DAC rule), JACK, and `rtkit` |
| `Windows/System32/localization.nix` | `Asia/Shanghai`, `en_US.UTF-8`/`zh_CN.UTF-8` locales, Fcitx5 Wayland, and Chrony (`wlp0s20f3`) |
| `Windows/System32/secrets.nix` | System `sops-nix` age key (`/var/lib/sops-nix/key.txt`), systemd secret activation, and `veracrypt-hhd-keyfile` declaration |
| `Windows/System32/hardware-configuration.nix` | Generated hardware scan, LUKS `cryptroot`, Btrfs subvolumes (`/`, `/home`, `/nix`), and `/boot` ESP |
| `Windows/Fonts/default.nix` | Desktop/CJK/Nerd fonts, fontconfig defaults, and early-boot `gallant` console font |
| `Windows/DRIVER/nvidia.nix` | NVIDIA open kernel module (`nvidiaPackages.latest`), modesetting/powerManagement, and disabled suspend/hybrid-sleep targets |
| `Users/mirin/home.nix` | Standalone Home Manager entrypoint, user overlays (including patched KDE `signon-*`), session variables, and `home.stateVersion` (`24.05`) |
| `Users/mirin/AppData/` | User modules: `Applications.nix` (apps, `udiskie`, `rclone-icloud`, `antigravity-hub`, `antigravity-cli`), `Desktop.nix`, `Gaming.nix`, `Graphics.nix`, `Secrets.nix`, `Development/` (`antigravity.nix`, `codex.nix`, `git.nix`, `toolchains.nix`), `Terminal/` (`shell.nix`, `tmux.nix`), `Media/`, and `Assets/Wallpapers/` |

## Behavioral Invariants

Do not alter these behaviors unless the user explicitly asks:

- **Boot, storage, & power**: Preserve kernel parameter order, Lanzaboote
  `/var/lib/sbctl` settings, Btrfs subvolumes, LUKS `cryptroot` FIDO2 unlock,
  the NVIDIA open driver configuration, and disabled suspend/hybrid-sleep
  targets.
- **Networking & policy routing**: Preserve `networking.nftables.flushRuleset = false`,
  firewall rules, reverse-path filter exceptions (`throne-tun`, `wlp0s20f3`,
  `eno1`, `virbr-win11`), Throne TUN + Tailscale exit node + LAN + NTP Wi-Fi
  (`table 123`) policy routing (`0x2023`/`0x2024`/`0x4000` marks), the
  `coding-vm`/`audit-vm` cgroupv2 kill-switch (`vm-cgroup-nft-sync` and LKL
  `preCheckRuleset`), and disabled `wait-online` units.
- **Desktop**: Keep Plasma 6 and SDDM Wayland enabled. Do not add declarative
  Plasma migration inputs (such as `plasma-manager`) or edit/reset live KDE
  files under `/home/mirin`.
- **Authentication**: Preserve initrd FIDO2 auto-unlock and narrow PAM U2F
  enablement (`kde`, `sudo`, `login` only).
- **Audio**: Preserve PipeWire/WirePlumber/JACK sample-rate settings and the
  `MOONDROP Dawn Pro` (`s32le` / `384000` Hz) rule.
- **Maintenance & mounts**: Preserve the `maintenance-without-store-vm` guard on
  `nh-clean`/`nix-gc`/`nix-optimise` (prevents store corruption while a VM
  shares `/nix/store`) and the non-disruptive `veracrypt-hhd` unit flags
  (`restartIfChanged = false`, `stopIfChanged = false`,
  `X-StopOnReconfiguration = false`).
- **Public flake interfaces**: Treat the five `packages.x86_64-linux` outputs
  and eight `overlays` outputs as stable public interfaces. Any addition,
  removal, or rename must be an explicit interface change.

## Secret Safety (SOPS + age)

- `.sops.yaml` may contain public age recipients (`*system`, `*mirin`) only.
- **Identities**:
  - System: `/var/lib/sops-nix/key.txt` (`root:root`, dir `0700`, file `0600`).
  - User: `/home/mirin/.config/sops/age/keys.txt` (`mirin:users`, dir `0700`,
    file `0600`).
- **Encrypted documents**:
  - `ProgramData/SOPS/system.json` is a binary-format SOPS JSON document (`data`
    key). Re-encrypt with:
    `sops --input-type binary --output-type json -e -i ProgramData/SOPS/system.json`
  - `ProgramData/SOPS/mirin.yaml` is an encrypted YAML SOPS document for user
    secrets (`Users/mirin/AppData/Secrets.nix`).
- Never place plaintext secrets, age private keys, tokens, or decrypted
  environment values in Nix expressions, `/nix/store`, command arguments, logs,
  or Git history. Do not create empty placeholder secret files.
- System and user consumers must read secrets from runtime paths
  (`config.sops.secrets.<name>.path`), never `builtins.readFile` or Nix string
  interpolation of secret contents.
- When encrypting new material, stage plaintext in a `0700` temporary directory,
  remove it immediately after encryption, and verify silent decryption to
  `/dev/null` for each intended identity.

## Validation Matrix

`nix flake check` builds both `rins` and `mirin` and runs `nix-style`
(`alejandra --check` + `deadnix --fail`). Match validation depth to the scope of
your edits:

| Change | Minimum validation |
| --- | --- |
| Any Nix edit | `nix fmt -- <files>`, `deadnix --fail --exclude Windows/System32/hardware-configuration.nix -- <files>`, `nix-instantiate --parse <files>`, `git diff --check` |
| Flake inputs/outputs | `nix flake show`, `nix flake check`, output-name and `flake.lock` node review |
| NixOS module | `nix eval .#nixosConfigurations.rins.config.system.build.toplevel.drvPath` and `nixos-rebuild build --flake .#rins` |
| Home Manager module | `nix eval .#homeConfigurations.mirin.activationPackage.drvPath` and `nix build .#homeConfigurations.mirin.activationPackage --no-link` |
| Custom package | `nix eval .#packages.x86_64-linux.<pkg>.drvPath` and `nix build .#<pkg> --no-link` |
| Python service script | `python3 -m unittest "Program Files/Scripts/test-vm-cgroup-nft-sync.py"` (or corresponding test suite) |
| SOPS / secret wiring | Option eval, `sops filestatus`, silent decrypt to `/dev/null` per recipient, generated unit/path check, filename-only worktree/history scan |
| Plasma / desktop | Verify no Plasma migration modules/options were introduced and eval Plasma 6 + SDDM Wayland enablement |
| Path move / refactor | Search old paths and relative imports; verify every imported module, source file, and patch exists |

Never report a network, permission, daemon, identity, or build blocker as a
pass; disclose the exact failure.

## Local Commits & Git Signing

Keep commits narrow, stage only task-relevant changes, and do not push unless
requested. Use **only** these two commit message formats:

```text
app: add|del|upgrade|downgrade|modified [software] vX.Y.Z
config: changed [description]
```

If software has no semantic version, use the 7-character revision from
`flake.lock` or its upstream `src` (extend only on collision); never invent
versions.

- **Signing key**: Default Git signing uses OpenPGP key
  `6CA74D44095DEBB5DA35444508A5B955EF921DC3` (`08A5B955EF921DC3`).
  The old signing subkey `2F31F8DA00E861F5C496FD993FEF51244D8595AF`
  (`3FEF51244D8595AF`) is revoked and was removed from this host's public
  keyring on 2026-11-02; do not restore it.
- Before troubleshooting signing, inspect effective `user.signingkey`,
  `gpg.format`, and `gpg.program`. `sec>` / `ssb>` indicate hardware-card keys.
- When verifying signatures, check the signing fingerprint, key status,
  `GOODSIG`, `VALIDSIG`, and exit status. Ignore an informational `KEYEXPIRED`
  notice on an unrelated old subkey when `GOODSIG`/`VALIDSIG` succeed on the
  active key; treat an applicable `REVKEYSIG` or `EXPKEYSIG` as a failure.
- Always attempt normal GPG signing first. Only fall back to `--no-gpg-sign` if
  the configured hardware/signing key is unavailable, and explicitly report the
  signing failure to the user.
