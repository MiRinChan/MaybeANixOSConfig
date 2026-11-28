{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  cmake,
  pkg-config,
  gtest,
}: let
  source = fetchFromGitHub {
    owner = "calagopus";
    repo = "fusequota";
    rev = "ad0b35fc2cadb3ce487ab7c4fa2a5b06aece1cfb";
    hash = "sha256-CCpkBeAVJN4i+/a+GYvJaLe1mzqCAxSqRCmlbP5WF88=";
  };
  fuse = stdenv.mkDerivation {
    pname = "fusequota-libfuse";
    version = "3.19.0-rc0";
    src = fetchFromGitHub {
      owner = "libfuse";
      repo = "libfuse";
      rev = "8916602c4007bfbb55af79eefc2d258c05b4c25e";
      hash = "sha256-ViHVyMSuJDShrdtEH570u2u3dn9iYCex4SnFetcJEFI=";
    };
    nativeBuildInputs = [meson ninja pkg-config];
    mesonFlags = [
      "-Dutils=false"
      "-Dexamples=false"
      "-Dtests=false"
      "-Duseroot=false"
      "-Denable-io-uring=false"
      "-Dsync-init=never"
    ];
  };
in
  stdenv.mkDerivation {
    pname = "fusequota";
    version = "0-unstable-ad0b35f";
    src = source;
    patches = [./fusequota-scan.patch];
    nativeBuildInputs = [cmake ninja pkg-config];
    buildInputs = [fuse gtest];
    postPatch = ''
      # Use the separately pinned shared library and the system GoogleTest.
      sed -i '/string(APPEND CMAKE_EXE_LINKER_FLAGS/d; /set(CMAKE_FIND_LIBRARY_SUFFIXES/d; /\''${FUSE3_STATIC_LIB}/d' CMakeLists.txt
      sed -i '/find_library(FUSE3_STATIC_LIB/,/^)/d' CMakeLists.txt
      substituteInPlace tests/CMakeLists.txt \
        --replace-fail '$<TARGET_FILE:fusequota>' "$out/bin/fusequota"
    '';
    cmakeFlags = ["-DFUSEQUOTA_BUILD_TESTS=ON"];
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      # This upstream test requires chown/setuid to nobody, unavailable in the builder.
      ctest --output-on-failure -L unit -E FailedRescanLeavesUsageUnchanged
      runHook postCheck
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 fusequota "$out/bin/fusequota"
      install -Dm755 tests/fusequota_tests "$out/libexec/fusequota-tests"
      runHook postInstall
    '';
    meta = {
      description = "FUSE filesystem with enforced disk quotas";
      homepage = "https://github.com/calagopus/fusequota";
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.linux;
      mainProgram = "fusequota";
    };
  }
