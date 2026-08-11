# Agent Instructions — NixOS Configuration

## Scope

This repository declares NixOS host `rins` and the standalone Home Manager
configuration for user `mirin`. It uses Windows-inspired directory names and a
mix of Chinese and English comments. Keep the single-host, single-user design
unless the user explicitly asks to generalize it.

The repository is authoritative only for declared state. Do not assume it
captures every piece of live machine or Plasma state.

## Environment entry

Before commands that need project dependencies, inspect `flake.nix`,
`flake.lock`, this file, and the relevant module. Simple read-only Git and file
inspection commands can run directly.

Use the pinned flake for evaluation, formatting, and builds:

```sh
nix fmt -- path/to/changed.nix
nix flake check
nix flake show
nix eval .#nixosConfigurations.rins.config.system.build.toplevel.drvPath
nixos-rebuild build --flake .#rins
nix eval .#homeConfigurations.mirin.activationPackage.drvPath
nix build .#homeConfigurations.mirin.activationPackage --no-link
nix build .#<package> --no-link
```

`nixos-rebuild build` and Home Manager builds are validation only. Do not run a
system or Home Manager switch unless the user explicitly asks. Home Manager is
standalone and is not activated by the NixOS configuration.

For paths containing spaces, quote shell paths and compose Nix paths from
`repoRoot`, for example `repoRoot + "/Program Files"`.

## Directory responsibilities

| Path | Responsibility |
| --- | --- |
| `flake.nix` | Inputs, package/overlay outputs, `rins`, and `mirin` entrypoints |
| `Program Files/default.nix` | Direct aggregation of system application and service modules |
| `Program Files/Applications/` | System applications, FHS support, gaming, hardware utilities, virtualization, and system tools |
| `Program Files/Services/` | Long-running services and network/device integration |
| `Program Files/Scripts/` | Service implementation scripts and their tests |
| `Program Files/Packages/` | Custom derivations, sources, and patches |
| `Program Files/Overlays/` | The eight public overlays and package-channel overlays |
| `ProgramData/SOPS/` | Encrypted SOPS documents only; never plaintext |
| `Windows/System32/default.nix` | System module aggregation only |
| `Windows/System32/configuration.nix` | Host glue, overlays, Catppuccin, and `system.stateVersion` |
| `Windows/System32/boot.nix` | Kernel, initrd, Lanzaboote, EFI, Plymouth, and boot parameters |
| `Windows/System32/networking.nix` | Hostname, NetworkManager, firewall, and wait-online behavior |
| `Windows/System32/nix.nix` | Nix settings, registries, caches, and optimisation |
| `Windows/System32/desktop.nix` | Plasma 6, SDDM, portals, dconf, and desktop session variables |
| `Windows/System32/services.nix` | Flatpak and host-wide device rules/workarounds |
| `Windows/System32/accounts.nix` | User account, groups, shell, and account session variables |
| `Windows/System32/authentication.nix` | Canokey/FIDO2 initrd and PAM authentication |
| `Windows/System32/audio.nix` | PipeWire, WirePlumber, JACK, and realtime audio |
| `Windows/System32/localization.nix` | Locale, timezone, NTP, and input method |
| `Windows/System32/secrets.nix` | System sops-nix key path, secret declarations, and runtime consumers |
| `Windows/Fonts/default.nix` | Fonts, fontconfig, and console font |
| `Windows/DRIVER/nvidia.nix` | NVIDIA and graphics configuration |
| `Users/mirin/home.nix` | Standalone Home Manager entrypoint and user overlays |
| `Users/mirin/AppData/` | User applications, desktop, development, terminal, media, and SOPS key configuration |

Do not restore the old `modules/nixos`, `modules/home-manager`, root `pkgs`, or
root `overlays` starter abstractions. Imports are explicit.

## Behavioral invariants

- Preserve boot/kernel parameter order, Lanzaboote settings, filesystems, LUKS,
  firewall rules, the `throne-tun` reverse-path exception, and wait-online
  workarounds unless the task explicitly changes them.
- Keep Plasma 6 and SDDM Wayland enabled. Do not restore declarative Plasma
  migration inputs or Home Manager migration declarations. Do not edit or reset
  KDE files under the user's home directory.
- Preserve the Canokey FIDO2 initrd flow and the narrow KDE/sudo PAM U2F
  settings.
- Preserve PipeWire/WirePlumber/JACK behavior and the USB DAC rule.
- The eight package outputs and eight overlay outputs are public flake
  interfaces. Treat additions, removals, and renames as explicit interface
  changes.
- `lunar.nix` has a known lazy `passthru.updateScript = ./update.sh` reference;
  do not broaden unrelated work to fix it without a request.

## Secret safety

- `.sops.yaml` may contain public age recipients only.
- `ProgramData/SOPS/system.yaml` must remain encrypted. Never put decrypted
  values, age identities, credentials, or environment-file contents in Nix
  expressions, command arguments, logs, Git diffs, or the Nix store.
- The system identity is `/var/lib/sops-nix/key.txt` (root, directory `0700`,
  file `0600`). The Home Manager identity is
  `/home/mirin/.config/sops/age/keys.txt` (mirin, directory `0700`, file `0600`).
- System services consume `config.sops.secrets.<name>.path`. Do not use
  `builtins.readFile` for secrets or interpolate secret content into a
  derivation.
- Use a `0700` temporary directory for plaintext encryption input, remove it
  immediately after encryption, and verify each intended identity can decrypt
  silently.
- Do not create an empty user secret document. Add `ProgramData/SOPS/mirin.yaml`
  only when a real user secret exists.

## Validation matrix

| Change | Minimum validation |
| --- | --- |
| Any Nix edit | Alejandra on changed files, `nix-instantiate --parse`, `git diff --check` |
| Flake/input/output | `nix flake check`, `nix flake show`, output-name and lock-node comparison |
| NixOS module | system drv eval and `nixos-rebuild build --flake .#rins` |
| Home Manager module | activation drv eval and activation package build |
| Package | output eval and `nix build .#<package> --no-link` |
| Proxy script | `PYTHONDONTWRITEBYTECODE=1` unit tests in a pinned Python environment |
| SOPS | option eval, `sops filestatus`, each-identity decrypt to `/dev/null`, and generated unit path review |
| Plasma/desktop | search for forbidden migration declarations and eval Plasma 6/SDDM enablement |
| Path move | search old roots and `../` imports; verify every import, source, and patch exists |
| Secret change | filename-only worktree/history scan; separate expected encrypted/public-recipient matches |

Never report a network, permission, identity, or build blocker as a pass.

## Local commits

Keep commits narrow and do not push unless requested. Use exactly these message
forms:

```text
app: add|del|upgrade|downgrade|modified [software] vX.Y.Z
config: changed [description]
```

If software has no semantic version, use the seven-character revision from
`flake.lock` or its source; extend only if it collides. Do not invent versions.
If normal signing fails because the configured key is unavailable, use
`--no-gpg-sign` and disclose that in the final report.
