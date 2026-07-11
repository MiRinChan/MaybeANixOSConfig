{
  autoPatchelfHook,
  bun,
  bunDeps,
  electron,
  lib,
  makeWrapper,
  nodejs_22,
  src,
  stdenv,
  version,
}:
stdenv.mkDerivation {
  pname = "openchamber-desktop";
  inherit src version;
  patches = [./disable-self-update.patch ./externalize-electron-deps.patch];

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
    export BUN="${lib.getExe bun}"
    bun run --cwd packages/electron build:web-assets
    bun run --cwd packages/electron bundle:main
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    desktopDir="$out/lib/openchamber-desktop"
    electronDir="$desktopDir/packages/electron"
    webDir="$desktopDir/packages/web"
    mkdir -p "$electronDir" "$webDir" "$out/bin"

    cp -a node_modules "$desktopDir/node_modules"

    mkdir -p "$electronDir/dist-bundle/resources"
    cp -a packages/electron/dist-bundle/main.mjs "$electronDir/dist-bundle/main.mjs"
    cp -a packages/electron/preload.mjs "$electronDir/dist-bundle/preload.mjs"
    cp -a packages/electron/preload.mjs "$electronDir/preload.mjs"
    cp -a packages/electron/package.json "$electronDir/package.json"
    cp -a packages/electron/node_modules "$electronDir/node_modules"
    cp -a packages/electron/resources/web-dist "$electronDir/dist-bundle/resources/web-dist"
    cp -a packages/electron/resources/icons "$electronDir/dist-bundle/resources/icons"

    cp -a packages/web/server "$webDir/server"
    cp -a packages/web/bin "$webDir/bin"
    cp -a packages/web/package.json "$webDir/package.json"
    [ -d packages/web/dist ] && cp -a packages/web/dist "$webDir/dist"
    [ -d packages/web/node_modules ] && cp -a packages/web/node_modules "$webDir/node_modules"

    find "$desktopDir" -xtype l -delete

    makeWrapper ${lib.getExe electron} "$out/bin/openchamber-desktop" \
      --add-flags "$electronDir" \
      --prefix PATH : ${lib.makeBinPath [bun nodejs_22]} \
      --set ELECTRON_IS_DEV 0

    install -Dm644 ${./openchamber-desktop.desktop} \
      "$out/share/applications/openchamber-desktop.desktop"
    install -Dm644 packages/electron/resources/icons/icon.png \
      "$out/share/icons/hicolor/1024x1024/apps/openchamber-desktop.png"
    install -Dm644 LICENSE "$out/share/licenses/openchamber-desktop/LICENSE"
    runHook postInstall
  '';

  meta = {
    description = "Electron desktop interface for the OpenCode AI agent";
    homepage = "https://github.com/openchamber/openchamber";
    license = lib.licenses.mit;
    mainProgram = "openchamber-desktop";
    platforms = ["x86_64-linux"];
  };
}
