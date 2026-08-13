{
  lib,
  fetchurl,
  fetchFromGitHub,
  runCommand,
  rustPlatform,
  pkg-config,
  wrapGAppsHook4,
  llvmPackages,
  pipewire,
  alsa-lib,
  gtk4,
  gtk4-layer-shell,
  glib,
  cairo,
  pango,
  gdk-pixbuf,
  graphene,
  wayland,
  openssl,
}: let
  sherpaArchive = fetchurl {
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.13.5/sherpa-onnx-v1.13.5-linux-x64-static-lib.tar.bz2";
    hash = "sha256-Kt6LfGLeZrnPLjK9fb4Het2qSxj0IrSdwb86Ggsfdi4=";
  };

  sherpaArchiveDir = runCommand "sherpa-onnx-archive" {} ''
    mkdir -p "$out"
    ln -s ${sherpaArchive} "$out/sherpa-onnx-v1.13.5-linux-x64-static-lib.tar.bz2"
  '';
in
  rustPlatform.buildRustPackage rec {
    pname = "tsuyaku";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "ocfox";
      repo = "tsuyaku";
      rev = "b8b563e2604936107e7aa41d99241fe4c2d8e55a";
      hash = "sha256-En/fR9Ms4O/nNhER8t625U2ODMd5CJJo0FO0Da/lET8=";
    };

    cargoLock.lockFile = "${src}/Cargo.lock";

    nativeBuildInputs = [
      pkg-config
      wrapGAppsHook4
      llvmPackages.clang
    ];

    buildInputs = [
      pipewire
      alsa-lib
      gtk4
      gtk4-layer-shell
      glib
      cairo
      pango
      gdk-pixbuf
      graphene
      wayland
      openssl
    ];

    LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
    SHERPA_ONNX_ARCHIVE_DIR = sherpaArchiveDir;

    meta = {
      description = "Real-time Wayland audio translator";
      homepage = "https://github.com/ocfox/tsuyaku";
      license = lib.licenses.mit;
      mainProgram = "tsuyaku";
      platforms = lib.platforms.linux;
    };
  }
