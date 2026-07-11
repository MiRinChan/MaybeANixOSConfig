{
  bun,
  stdenvNoCC,
  src,
  version,
}:
stdenvNoCC.mkDerivation {
  pname = "openchamber-bun-deps";
  inherit src version;

  nativeBuildInputs = [bun];
  dontConfigure = true;
  dontFixup = true;

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
    cp -a node_modules "$out/node_modules"
    for wsnm in packages/*/node_modules; do
      [ -d "$wsnm" ] || continue
      pkg="$(basename "$(dirname "$wsnm")")"
      mkdir -p "$out/packages/$pkg/node_modules"
      cp -a "$wsnm/." "$out/packages/$pkg/node_modules/"
    done
    runHook postInstall
  '';

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = "sha256-mkfEn6o5FKldOkdrPwqR4HfHZJ09gzP6NPYbfvd+qss=";
}
