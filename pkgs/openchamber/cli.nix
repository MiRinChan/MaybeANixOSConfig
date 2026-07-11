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

  nativeBuildInputs = [
    autoPatchelfHook
    bun
    makeWrapper
    nodejs_22
  ];
  buildInputs = [stdenv.cc.cc.lib];
  autoPatchelfIgnoreMissingDeps = ["libc.musl-x86_64.so.1"];

  configurePhase = ''
    runHook preConfigure
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    cp -a "${bunDeps}/node_modules" ./node_modules
    chmod -R u+w node_modules
    for wsnm in "${bunDeps}"/packages/*/node_modules; do
      [ -d "$wsnm" ] || continue
      pkg="$(basename "$(dirname "$wsnm")")"
      mkdir -p "./packages/$pkg/node_modules"
      cp -a "$wsnm/." "./packages/$pkg/node_modules/"
      chmod -R u+w "./packages/$pkg/node_modules"
    done
    for nm in node_modules packages/*/node_modules; do
      [ -d "$nm" ] && patchShebangs "$nm"
    done
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    bun run --cwd packages/web build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/openchamber/packages/web" "$out/bin"
    cp -a node_modules "$out/lib/openchamber/node_modules"
    cp -a packages/web/bin packages/web/server packages/web/dist \
      packages/web/public packages/web/package.json \
      "$out/lib/openchamber/packages/web/"
    if [ -d packages/web/node_modules ]; then
      cp -a packages/web/node_modules "$out/lib/openchamber/packages/web/node_modules"
    fi
    makeWrapper ${lib.getExe nodejs_22} "$out/bin/openchamber" \
      --add-flags "$out/lib/openchamber/packages/web/bin/cli.js" \
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
