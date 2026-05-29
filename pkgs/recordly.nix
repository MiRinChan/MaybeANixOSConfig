{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  autoPatchelfHook,
  electron_39,
  ffmpeg_7-full,
  whisper-cpp,
  nodejs_22,
  libx11,
  libxrandr,
  libxt,
  libxtst,
}:
buildNpmPackage rec {
  pname = "recordly";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "webadderallorg";
    repo = "Recordly";
    rev = "v${version}";
    hash = "sha256-F299bt0GJxrhS8eRDJ2OxnEDrVmV5VZN3xn9LS/Wgc0=";
  };

  npmDepsHash = "sha256-7W2SErZIWZuYek0gJgRuDeiLoPyGFYf4x1oFffrZruQ=";

  patches = [
    ./recordly-linux-hud-hover.patch
  ];

  nodejs = nodejs_22;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = [
    libx11
    libxrandr
    libxt
    libxtst
  ];

  npmFlags = ["--ignore-scripts"];

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = 1;

  buildPhase = ''
    runHook preBuild

    npm run build:native-helpers
    npm run build:windows-capture
    npm run build:windows-gpu-export
    npm run build:nvidia-cuda-compositor
    npm run build:cursor-monitor
    npx tsc
    npx vite build --config vite.config.ts
    npm run normalize:electron-main-cjs
    npm run smoke:electron-main-cjs
    npm prune --omit=dev --ignore-scripts

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    appDir="$out/share/recordly"
    mkdir -p "$appDir" "$out/bin"

    cp -r package.json dist dist-electron electron public node_modules "$appDir/"

    for icon in icons/icons/png/*.png; do
      size="$(basename "$icon" .png)"
      install -Dm0644 "$icon" "$out/share/icons/hicolor/$size/apps/recordly.png"
    done

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper ${lib.getExe electron_39} "$out/bin/recordly" \
      --add-flags "$out/share/recordly" \
      --prefix PATH : ${lib.makeBinPath [ffmpeg_7-full whisper-cpp]} \
      --set WHISPER_CPP_PATH ${lib.getExe' whisper-cpp "whisper-cli"} \
      --set RECORDLY_DISABLE_AUTO_UPDATES 1 \
      --add-flags '--enable-features=WebRTCPipeWireCapturer''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+,UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime=true}}'
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "recordly";
      exec = "recordly %U";
      icon = "recordly";
      desktopName = "Recordly";
      genericName = "Screen Recorder";
      comment = meta.description;
      categories = ["AudioVideo" "Recorder"];
      startupWMClass = "Recordly";
    })
  ];

  meta = {
    description = "Creator-focused screen recorder with auto-zoom, cursor effects, backgrounds, and annotations";
    homepage = "https://github.com/webadderallorg/Recordly";
    changelog = "https://github.com/webadderallorg/Recordly/releases/tag/v${version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "recordly";
    platforms = ["x86_64-linux"];
  };
}
