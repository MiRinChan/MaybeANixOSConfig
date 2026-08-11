# OpenChamber Packages Design

## Goal

Package OpenChamber 1.15.0 from source as two independently installable Nix
derivations:

- `openchamber`: the CLI, Web UI, and PWA assets.
- `openchamber-desktop`: the Electron desktop application for Linux.

Both packages must be reproducible, available through the repository's
`additions` overlay, and usable from standalone Home Manager. The repository
must not contain downloaded archives, dependency trees, or binary artifacts.

## Upstream Version and Supported Platform

Both derivations use the official `v1.15.0` release at commit
`5127f5c889204a21eea7904cc5686452b807a9fa`. The source fetch and dependency
closure are content-addressed with Nix hashes.

The packages support `x86_64-linux`, matching this flake's current `systems`
list. Cross-platform and multi-host abstractions are out of scope.

OpenChamber 1.15.0 uses the Electron desktop runtime. The older Tauri desktop
runtime used by the AUR `openchamber-desktop` packages was removed upstream
before 1.15.0. The AUR recipes remain useful as packaging references for
distribution-managed updates, desktop integration, and avoiding bundled
runtime downloads, but their Tauri binaries and sidecar layout are not copied.

## Package Layout

The implementation lives under `Program Files/Packages/openchamber/`:

- `default.nix` defines shared release metadata and dispatches the two package
  recipes.
- `cli.nix` builds and installs the CLI/Web/PWA package.
- `desktop.nix` builds and installs the Electron desktop package.
- Text patches are kept beside the recipes only when source substitution is
  insufficient or would be fragile.

`Program Files/Packages/default.nix` exports both packages with `callPackage`:

- `openchamber`
- `openchamber-desktop`

The existing `outputs.overlays.additions` overlay already imports
`Program Files/Packages/default.nix` into Home Manager, so no Home Manager module is required.
Neither package is added to the current user's `home.packages` automatically.

## Shared Source and Dependency Model

The package recipes share the same `fetchFromGitHub` result for OpenChamber
1.15.0. Nix deduplicates this fixed-output source in the store.

Upstream declares `bun@1.3.14` and provides `bun.lock`. The build uses the
locked dependency graph and a separately hashed dependency cache. Dependency
acquisition occurs only in a fixed-output derivation; application build phases
run offline with the frozen lock file. Native packages are rebuilt inside the
Nix build environment rather than copied from an upstream release.

If the pinned nixpkgs Bun version cannot consume the 1.15.0 lock file, the
package must supply a source-built or independently fixed Bun 1.3.14 build
input. Relaxing the lock file or performing an unlocked install is not an
acceptable fallback.

No `node_modules`, Bun cache, source archive, Electron distribution, AppImage,
Debian package, Pacman package, OpenCode executable, or other binary artifact
is committed to the repository.

## CLI/Web Derivation

`openchamber` builds the shared UI and `packages/web` production assets. It
installs:

- the `openchamber` command from `packages/web/bin/cli.js`;
- the Web server sources required at runtime;
- built Web/PWA assets;
- the locked runtime dependency tree, including native Node modules.

The command is wrapped with the required Node/Bun runtime and dynamic-library
search paths. The packaged command must work without a writable installation
directory.

OpenChamber's self-update command is incompatible with an immutable Nix store.
The package disables the mutation path and returns an actionable message that
updates are managed through Nix/Home Manager. Commands that write user data or
configure user services remain supported when they target normal XDG user
directories.

## Desktop Derivation

`openchamber-desktop` builds the Web assets and Electron main/preload bundles
from the same 1.15.0 source. It uses nixpkgs' system Electron 41 instead of
allowing Electron or electron-builder to download an Electron distribution.
The current pinned nixpkgs exposes Electron 41.9.1, which is ABI-compatible at
the Electron major-version boundary with upstream's Electron 41 dependency.

Native modules such as `better-sqlite3` and PTY bindings are rebuilt for the
system Electron ABI. The package directly installs the unpacked application
payload; it does not create and re-extract an AppImage, `.deb`, `.pacman`, or
other distribution archive.

The package installs:

- application JavaScript and Web assets under `$out/lib/openchamber-desktop`;
- an `openchamber-desktop` wrapper under `$out/bin` that launches the system
  Electron runtime;
- a freedesktop desktop entry;
- upstream icons in the hicolor icon tree;
- the upstream license.

The wrapper supplies runtime library paths and places `opencode` on `PATH`
when it is installed in the user's environment. The package does not download
or embed the OpenCode release binary. OpenChamber's existing runtime discovery
continues to honor explicit OpenCode path/environment overrides before finding
`opencode` on `PATH`.

The Electron auto-updater is disabled because upgrades are controlled by Nix.
Desktop data remains in the normal user configuration/data directories and is
not written into the package output.

## Reproducibility and Security Boundaries

- Source revision, source content, and dependency content are hash-pinned.
- Application compilation has no network access.
- The dependency lock file is mandatory and frozen.
- Updater code cannot mutate the package output or replace the executable.
- System Electron is used instead of an upstream-downloaded Electron binary.
- OpenCode is discovered from the declarative user environment instead of
  being downloaded during the Desktop build.
- Generated outputs are checked for references to temporary build paths.
- Only source recipes and necessary text patches are committed.

## Verification

Verification proceeds from the narrowest artifact to the complete host
configuration:

1. Evaluate both flake package attributes.
2. Build `.#openchamber` and `.#openchamber-desktop` independently.
3. Run `openchamber --version` and `openchamber --help` from the CLI result.
4. Confirm the CLI starts in foreground mode and reaches its local health or
   HTTP endpoint without downloading dependencies.
5. Launch the desktop result in a bounded smoke test and check its logs for a
   successfully created Electron window/server, then terminate it cleanly.
6. Inspect both closures and installed files to confirm there is no bundled
   Electron distribution, OpenCode executable, package archive, or temporary
   build path.
7. Run the package-relevant upstream tests that can execute offline.
8. Run `nix fmt`.
9. Run `nixos-rebuild build --flake .#rins` without activating the result.

If an upstream test requires network access or a graphical interaction that
cannot be automated reliably, the implementation records that limitation and
uses a narrower offline or process-level assertion instead. A successful Nix
build alone is not sufficient evidence that the package runs.

## Non-Goals

- Automatically adding either package to the user's Home Manager package list.
- Adding a Home Manager service module for OpenChamber or OpenCode.
- Supporting `aarch64-linux`, macOS, or Windows.
- Restoring the removed Tauri desktop implementation.
- Shipping an upstream release binary as a fallback.
- Following the moving `main` branch or an AUR `-git` package.
