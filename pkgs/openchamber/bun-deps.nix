{
  bun,
  lib,
  stdenvNoCC,
  src,
  version,
}:
stdenvNoCC.mkDerivation {
  pname = "openchamber-bun-deps";
  inherit src version;

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
