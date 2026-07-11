# OpenChamber Packages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build OpenChamber 1.15.0 from source as independently installable `openchamber` CLI/Web/PWA and `openchamber-desktop` Electron packages.

**Architecture:** A small package scope under `pkgs/openchamber/` owns one hash-pinned upstream source and one hash-pinned Bun dependency cache. The CLI and Desktop recipes consume those shared inputs but build separate runtime closures; Desktop launches through nixpkgs Electron 41 and discovers `opencode` from the user environment instead of embedding it.

**Tech Stack:** Nix, `fetchFromGitHub`, Bun 1.3.x with `bun.lock`, Node.js 22+, Vite, Electron 41, native Node addons, Home Manager overlays.

## Global Constraints

- Fix both packages to OpenChamber `v1.15.0`, commit `5127f5c889204a21eea7904cc5686452b807a9fa`.
- Support only `x86_64-linux`.
- Use the upstream `bun.lock` with `bun install --frozen-lockfile`; never regenerate or relax it.
- Permit network access only in fixed-output fetch/dependency derivations.
- Commit only Nix expressions and necessary text patches; never commit archives, dependency trees, or binaries.
- Do not bundle Electron, OpenCode, AppImage, Deb, Pacman, or another distribution archive.
- Export `openchamber` and `openchamber-desktop` through `pkgs/default.nix` and the existing additions overlay.
- Do not add either package to the user's `home.packages` automatically.
- Disable application self-update paths that would mutate a Nix installation.
- Use the repository's declared flake environment and run `nix fmt` before completion.

---

## File Map

- Create `pkgs/openchamber/default.nix`: shared version/source/dependency-cache scope and public `cli`/`desktop` members.
- Create `pkgs/openchamber/bun-deps.nix`: fixed-output Bun package cache generated from `bun.lock`.
- Create `pkgs/openchamber/cli.nix`: CLI/Web/PWA source build and immutable-update behavior.
- Create `pkgs/openchamber/desktop.nix`: system-Electron build, native-addon rebuild, wrapper, icon, and desktop entry.
- Create `pkgs/openchamber/disable-self-update.patch`: CLI and Electron updater changes with a Nix-specific diagnostic.
- Modify `pkgs/default.nix`: expose `openchamber` and `openchamber-desktop` with `callPackage`.

### Task 1: Establish the shared package scope and public attributes

**Files:**
- Create: `pkgs/openchamber/default.nix`
- Create: `pkgs/openchamber/bun-deps.nix`
- Modify: `pkgs/default.nix`

**Interfaces:**
- Produces: `pkgs.openchamber` and `pkgs.openchamber-desktop` derivations.
- Produces: shared `version`, `src`, and `bunDeps` values passed to `cli.nix` and `desktop.nix`.
- Consumes: the repository's existing `pkgs.callPackage` convention and additions overlay.

- [ ] **Step 1: Record the failing public-interface check**

Run:

```bash
nix eval .#openchamber.pname
nix eval .#openchamber-desktop.pname
```

Expected: both commands fail because neither flake package attribute exists.

- [ ] **Step 2: Add the shared package scope with deliberately failing hashes**

Create `pkgs/openchamber/default.nix`:

```nix
{
  lib,
  callPackage,
  fetchFromGitHub,
}:
let
  version = "1.15.0";
  src = fetchFromGitHub {
    owner = "openchamber";
    repo = "openchamber";
    rev = "5127f5c889204a21eea7904cc5686452b807a9fa";
    hash = lib.fakeHash;
  };
  bunDeps = callPackage ./bun-deps.nix {
    inherit src version;
  };
in {
  cli = callPackage ./cli.nix {
    inherit bunDeps src version;
  };
  desktop = callPackage ./desktop.nix {
    inherit bunDeps src version;
  };
}
```

Create `pkgs/openchamber/bun-deps.nix` as a fixed-output cache derivation:

```nix
{
  bun,
  lib,
  stdenvNoCC,
  src,
  version,
}:
stdenvNoCC.mkDerivation {
  pname = "openchamber-bun-deps";
  inherit version src;

  nativeBuildInputs = [bun];
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    export HOME="$TMPDIR/home"
    export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"
    mkdir -p "$HOME" "$BUN_INSTALL_CACHE_DIR"
    bun install --frozen-lockfile --ignore-scripts
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a "$BUN_INSTALL_CACHE_DIR/." "$out/"
    runHook postInstall
  '';

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = lib.fakeHash;
}
```

Temporarily create minimal `cli.nix` and `desktop.nix` derivations solely so
the source fetch can be forced:

```nix
{stdenvNoCC, src, version, ...}:
stdenvNoCC.mkDerivation {
  pname = "openchamber-bootstrap";
  inherit src version;
  dontBuild = true;
  installPhase = "mkdir -p $out";
}
```

- [ ] **Step 3: Register both public packages**

Wrap the existing returned package set in a `let` binding:

```nix
pkgs: let
  openchamberPackages = pkgs.callPackage ./openchamber {};
in {
  openchamber = openchamberPackages.cli;
  openchamber-desktop = openchamberPackages.desktop;
```

Keep `openchamberPackages` private to the expression so the flake `packages`
output contains derivations rather than an internal attribute set.

- [ ] **Step 4: Resolve and pin the source hash**

Run:

```bash
nix build .#openchamber 2>&1 | tee /tmp/openchamber-source-hash.log
```

Expected: a fixed-output hash mismatch that prints the actual SRI hash for
commit `5127f5c889204a21eea7904cc5686452b807a9fa`.

Replace only `src.hash = lib.fakeHash;` with the exact `got: sha256-...` value,
then rerun:

```bash
nix build .#openchamber
```

Expected: the temporary bootstrap derivation builds.

- [ ] **Step 5: Verify the public interface**

Run:

```bash
nix eval --raw .#openchamber.pname
nix eval --raw .#openchamber-desktop.pname
```

Expected: both evaluate to `openchamber-bootstrap` at this temporary stage,
proving the two attributes are wired before their implementations diverge.

- [ ] **Step 6: Commit the package scope**

```bash
git add pkgs/default.nix pkgs/openchamber/default.nix pkgs/openchamber/bun-deps.nix pkgs/openchamber/cli.nix pkgs/openchamber/desktop.nix
git commit -m "package: scaffold OpenChamber source packages"
```

### Task 2: Build the reproducible CLI/Web/PWA package

**Files:**
- Modify: `pkgs/openchamber/bun-deps.nix`
- Replace: `pkgs/openchamber/cli.nix`

**Interfaces:**
- Consumes: `src`, `version`, and the fixed-output `bunDeps` cache.
- Produces: `$out/bin/openchamber`, `$out/lib/openchamber`, and Web/PWA assets.
- Produces: an offline runtime closure suitable for `home.packages`.

- [ ] **Step 1: Force the Bun dependency-cache hash failure**

Run:

```bash
nix build .#openchamber 2>&1 | tee /tmp/openchamber-bun-deps-hash.log
```

Expected: `openchamber-bun-deps` fails with a fixed-output hash mismatch and
prints its actual recursive SRI hash. If Bun 1.3.13 rejects the 1.3.14 lock
format, first test the pinned unstable Bun 1.3.11; if both reject it, package
Bun 1.3.14 as a separately hash-pinned build input before continuing. Never
rewrite `bun.lock`.

- [ ] **Step 2: Pin the dependency cache and prove offline installation**

Replace `outputHash = lib.fakeHash;` with the exact hash printed in Step 1.
Then run the ordinary consumer derivation, which has no fixed-output network
permission:

```bash
nix build -L .#openchamber
```

Expected: dependency installation completes from `${bunDeps}` without network
access. If Bun lacks a usable `--offline` switch, omit only that command-line
flag; the normal Nix sandbox remains the enforcement boundary and any network
attempt fails the build.

- [ ] **Step 3: Replace the bootstrap CLI with the source build**

Write `pkgs/openchamber/cli.nix` as a `stdenv.mkDerivation` with these exact
phase responsibilities:

```nix
{
  autoPatchelfHook,
  bun,
  bunDeps,
  lib,
  makeWrapper,
  nodejs_22,
  src,
  stdenv,
  version,
}:
stdenv.mkDerivation {
  pname = "openchamber";
  inherit src version;

  nativeBuildInputs = [autoPatchelfHook bun makeWrapper];
  buildInputs = [stdenv.cc.cc.lib];

  configurePhase = ''
    runHook preConfigure
    export HOME="$TMPDIR/home"
    export BUN_INSTALL_CACHE_DIR="${bunDeps}"
    bun install --frozen-lockfile --offline
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    bun run --cwd packages/ui build
    bun run --cwd packages/web build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/openchamber" "$out/bin"
    cp -a packages/web/bin packages/web/server packages/web/dist \
      packages/web/public packages/web/package.json "$out/lib/openchamber/"
    cp -a node_modules "$out/lib/openchamber/node_modules"
    makeWrapper ${lib.getExe nodejs_22} "$out/bin/openchamber" \
      --add-flags "$out/lib/openchamber/bin/cli.js" \
      --prefix PATH : ${lib.makeBinPath [bun nodejs_22]}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    "$out/bin/openchamber" --version | grep -F "${version}"
    "$out/bin/openchamber" --help | grep -F "openchamber"
  '';

  meta = {
    description = "Web and PWA interface for the OpenCode AI agent";
    homepage = "https://github.com/openchamber/openchamber";
    license = lib.licenses.mit;
    mainProgram = "openchamber";
    platforms = ["x86_64-linux"];
  };
}
```

Before committing, reconcile the exact upstream build command and output paths
with `packages/ui/package.json`, `packages/web/package.json`, and the build
scripts at v1.15.0. Keep the interface and offline constraints above unchanged.

- [ ] **Step 4: Build and run the CLI checks**

Run:

```bash
nix build -L .#openchamber
./result/bin/openchamber --version
./result/bin/openchamber --help
```

Expected: build succeeds; version output includes `1.15.0`; help exits zero.

- [ ] **Step 5: Smoke-test the Web server without managed OpenCode startup**

Run the result with `OPENCODE_SKIP_START=true`, a temporary data directory,
foreground mode, and a fixed localhost port. Poll its documented health route
or root page, then terminate the process:

```bash
tmpdir=$(mktemp -d)
HOME="$tmpdir" OPENCODE_SKIP_START=true ./result/bin/openchamber serve \
  --host 127.0.0.1 --port 18731 --foreground &
pid=$!
for attempt in $(seq 1 30); do
  curl -fsS http://127.0.0.1:18731/ >/tmp/openchamber-root.html && break
  sleep 1
done
kill "$pid"
wait "$pid" || true
test -s /tmp/openchamber-root.html
```

Expected: the root request succeeds and produces non-empty HTML.

- [ ] **Step 6: Commit the CLI package**

```bash
git add pkgs/openchamber/bun-deps.nix pkgs/openchamber/cli.nix
git commit -m "package: build OpenChamber CLI from source"
```

### Task 3: Disable store-mutating CLI updates

**Files:**
- Create: `pkgs/openchamber/disable-self-update.patch`
- Modify: `pkgs/openchamber/cli.nix`

**Interfaces:**
- Consumes: upstream CLI update command dispatch at v1.15.0.
- Produces: a stable nonzero or informational update result that directs users
  to Nix/Home Manager without writing under `$out`.

- [ ] **Step 1: Demonstrate the unpatched update behavior**

Run the packaged command with a temporary home and capture output:

```bash
tmpdir=$(mktemp -d)
HOME="$tmpdir" ./result/bin/openchamber update 2>&1 | tee /tmp/openchamber-update-before.log
```

Expected: the command attempts upstream update discovery or mutation rather
than reporting that Nix manages the package.

- [ ] **Step 2: Patch the exact update dispatch**

Locate the `update` command handler in `packages/web/bin/cli.js` and create a
minimal unified diff that replaces its update body with:

```js
console.error('OpenChamber is managed by Nix; update it through your flake or Home Manager configuration.');
process.exitCode = 1;
return;
```

Add the patch to `patches` in `cli.nix`:

```nix
  patches = [./disable-self-update.patch];
```

If the Electron updater uses a separate call site, include that second hunk in
the same patch so `desktop.nix` can reuse it.

- [ ] **Step 3: Verify immutable update behavior**

Rebuild and run:

```bash
nix build -L .#openchamber
tmpdir=$(mktemp -d)
HOME="$tmpdir" ./result/bin/openchamber update 2>&1 | tee /tmp/openchamber-update-after.log
grep -F "managed by Nix" /tmp/openchamber-update-after.log
```

Expected: the diagnostic is present and no network fetch or package-output
write is attempted.

- [ ] **Step 4: Commit the updater policy**

```bash
git add pkgs/openchamber/cli.nix pkgs/openchamber/disable-self-update.patch
git commit -m "package: disable OpenChamber self updates"
```

### Task 4: Build the Electron desktop package with system Electron

**Files:**
- Replace: `pkgs/openchamber/desktop.nix`
- Modify if needed: `pkgs/openchamber/disable-self-update.patch`

**Interfaces:**
- Consumes: shared `src`, `version`, `bunDeps`, and updater patch.
- Consumes: nixpkgs `electron` 41.9.1 and its headers/runtime.
- Produces: `$out/lib/openchamber-desktop`, `$out/bin/openchamber-desktop`,
  freedesktop metadata, hicolor icons, and license data.

- [ ] **Step 1: Make the desktop implementation fail at the right boundary**

Replace the bootstrap `desktop.nix` with a derivation that builds Web assets
and Electron bundles but still lacks native-addon rebuilding. Run:

```bash
nix build -L .#openchamber-desktop
```

Expected: failure identifies the first Electron ABI/native-addon or missing
resource boundary, proving the Desktop build is no longer the bootstrap.

- [ ] **Step 2: Implement offline Electron asset and main-process builds**

Use `bunDeps` for frozen offline installation, then run only source-producing
upstream scripts:

```bash
bun run --cwd packages/electron build:web-assets
bun run --cwd packages/electron bundle:main
```

Do not run `packages/electron/scripts/prepare-opencode-cli.mjs` or the complete
`package` script because those paths download OpenCode and invoke
electron-builder distribution packaging.

- [ ] **Step 3: Rebuild native modules for Electron 41**

Configure `@electron/rebuild` to use the system Electron version and local
headers/source supplied by nixpkgs. Rebuild the modules loaded by the Web
server and Electron process, including `better-sqlite3`, `node-pty`, and other
`.node` dependencies discovered by `find node_modules -name '*.node'`.

The build must not contact `electronjs.org` or GitHub. Pass the Electron major
and architecture explicitly and point the rebuild tooling at the nixpkgs
Electron headers. Fail the build if a native module still targets the Node/Bun
ABI instead of Electron 41.

- [ ] **Step 4: Install the unpacked application directly**

Install these inputs under `$out/lib/openchamber-desktop`:

```text
packages/electron/dist-bundle/main.mjs
packages/electron/preload.mjs
packages/electron/resources/web-dist/
packages/electron/resources/icons/
packages/web/server/
packages/web/package.json
node_modules/
```

Create `$out/bin/openchamber-desktop` with `makeWrapper` around nixpkgs
Electron:

```nix
makeWrapper ${lib.getExe electron} "$out/bin/openchamber-desktop" \
  --add-flags "$out/lib/openchamber-desktop" \
  --prefix PATH : ${lib.makeBinPath [bun nodejs_22]} \
  --set ELECTRON_IS_DEV 0
```

Set the installed application's `package.json` main field to
`dist-bundle/main.mjs`; do not fabricate an asar or archive.

- [ ] **Step 5: Add desktop integration from source assets**

Install a generated text desktop entry at
`$out/share/applications/openchamber-desktop.desktop`:

```ini
[Desktop Entry]
Name=OpenChamber
Comment=Desktop interface for the OpenCode AI agent
Exec=openchamber-desktop %U
Icon=openchamber-desktop
Terminal=false
Type=Application
Categories=Development;
StartupWMClass=openchamber-desktop
StartupNotify=true
```

Copy the largest upstream PNG icon to the matching hicolor size directory and
install `LICENSE` under `$out/share/licenses/openchamber-desktop/LICENSE`.

- [ ] **Step 6: Build and inspect the Desktop result**

Run:

```bash
nix build -L .#openchamber-desktop
test -x result/bin/openchamber-desktop
test -f result/share/applications/openchamber-desktop.desktop
test -f result/share/licenses/openchamber-desktop/LICENSE
```

Expected: all checks succeed and no AppImage/deb/pacman phase appears in the
build log.

- [ ] **Step 7: Commit the Desktop package**

```bash
git add pkgs/openchamber/desktop.nix pkgs/openchamber/disable-self-update.patch
git commit -m "package: build OpenChamber Desktop with system Electron"
```

### Task 5: Prove Desktop runtime and closure policy

**Files:**
- Modify if required by observed runtime failure: `pkgs/openchamber/desktop.nix`
- Modify if required by observed updater behavior: `pkgs/openchamber/disable-self-update.patch`

**Interfaces:**
- Consumes: the built Desktop package and the user's existing `opencode` on
  `PATH`.
- Produces: runtime evidence that the Electron shell starts without embedded
  Electron/OpenCode or a writable package directory.

- [ ] **Step 1: Run a bounded Electron smoke test**

Use a temporary home and capture logs. Under an active Plasma graphical
session, launch normally; in a headless build shell, use the Electron ozone
headless flags or `xvfb-run` when available:

```bash
tmpdir=$(mktemp -d)
HOME="$tmpdir" ELECTRON_ENABLE_LOGGING=1 result/bin/openchamber-desktop \
  --enable-logging=stderr >/tmp/openchamber-desktop.log 2>&1 &
pid=$!
sleep 15
kill "$pid"
wait "$pid" || true
sed -n '1,240p' /tmp/openchamber-desktop.log
```

Expected: Electron starts the local OpenChamber server/window and does not log
a missing native-module ABI error, a resource-path failure, or an updater
download.

- [ ] **Step 2: Verify OpenCode discovery without bundling it**

Run:

```bash
test ! -e result/lib/openchamber-desktop/resources/opencode-cli
find result -type f -name opencode -print -quit | test ! -s /dev/stdin
PATH="$(dirname "$(command -v opencode)"):$PATH" \
  HOME="$(mktemp -d)" result/bin/openchamber-desktop \
  --enable-logging=stderr >/tmp/openchamber-desktop-opencode.log 2>&1 &
pid=$!
sleep 15
kill "$pid"
wait "$pid" || true
```

Expected: no bundled OpenCode executable exists and Desktop does not report
that OpenCode is unavailable.

- [ ] **Step 3: Audit forbidden artifacts and build-path leakage**

Run against both package results:

```bash
cli=$(nix build --no-link --print-out-paths .#openchamber)
desktop=$(nix build --no-link --print-out-paths .#openchamber-desktop)
find "$cli" "$desktop" -type f \
  \( -name '*.AppImage' -o -name '*.deb' -o -name '*.pacman' \
     -o -name '*.tar' -o -name '*.tar.gz' -o -name '*.zip' \) -print
rg -a -n '/build/|/tmp/openchamber' "$cli" "$desktop"
```

Expected: both commands produce no matches. If upstream dependencies contain
data archives required at runtime, inspect each match and narrow the assertion
to distribution/build artifacts rather than deleting runtime data blindly.

- [ ] **Step 4: Audit dependency closures**

Run:

```bash
nix-store -q --references "$(nix build --no-link --print-out-paths .#openchamber)"
nix-store -q --references "$(nix build --no-link --print-out-paths .#openchamber-desktop)"
```

Expected: Desktop references the nixpkgs Electron derivation; neither closure
contains a separately downloaded Electron release or OpenCode release asset.

- [ ] **Step 5: Commit runtime corrections, if the smoke test required them**

```bash
git add pkgs/openchamber/desktop.nix pkgs/openchamber/disable-self-update.patch
git diff --cached --quiet || git commit -m "fix: complete OpenChamber Desktop runtime wiring"
```

### Task 6: Final repository verification and Home Manager exposure

**Files:**
- Modify only if validation finds a package defect: files under `pkgs/openchamber/` or `pkgs/default.nix`

**Interfaces:**
- Consumes: both completed derivations.
- Produces: formatting, package-level, Home Manager evaluation, and complete
  NixOS build evidence.

- [ ] **Step 1: Format and inspect the exact diff**

Run:

```bash
nix fmt
git diff --check
git status --short
git diff -- pkgs/default.nix pkgs/openchamber docs/superpowers
```

Expected: formatting succeeds, there are no whitespace errors, and unrelated
user files are absent from the diff.

- [ ] **Step 2: Run package-level checks from clean result paths**

Run:

```bash
nix build -L .#openchamber
nix build -L .#openchamber-desktop
"$(nix build --no-link --print-out-paths .#openchamber)"/bin/openchamber --version
"$(nix build --no-link --print-out-paths .#openchamber)"/bin/openchamber --help
```

Expected: both builds succeed; CLI version includes `1.15.0`; help exits zero.

- [ ] **Step 3: Prove Home Manager can resolve both overlay packages**

Run:

```bash
nix eval --raw .#homeConfigurations.mirin.pkgs.openchamber.pname
nix eval --raw .#homeConfigurations.mirin.pkgs.openchamber-desktop.pname
```

Expected output:

```text
openchamber
openchamber-desktop
```

- [ ] **Step 4: Build the complete NixOS configuration without activation**

Run:

```bash
nixos-rebuild build --flake .#rins
```

Expected: the `rins` system closure builds successfully. Do not run `switch`.

- [ ] **Step 5: Review final repository state and commit validation fixes**

Run:

```bash
git status --short
git diff --check
git log -6 --oneline
```

If formatting or validation changed tracked package files, commit only those
files:

```bash
git add pkgs/default.nix pkgs/openchamber
git diff --cached --quiet || git commit -m "package: finalize OpenChamber validation"
```

Expected: all implementation files are committed, and any unrelated preexisting
work remains untouched.
