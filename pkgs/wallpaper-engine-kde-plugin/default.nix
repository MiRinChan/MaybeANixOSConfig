# from: https://github.com/kostek001/pkgs/blob/3cb276f1d4b460c5c001cb2d0de2b8cf9f369ea0/pkgs/desktop/plasma/wallpaper-engine-kde-plugin/default.nix
{
  stdenv,
  fetchFromGitHub,
  cmake,
  qt6,
  kdePackages,
  pkg-config,
  vulkan-headers,
  mpv,
  libass,
  lz4,
  fribidi,
  python3,
  lib,
}: let
  pythonPath = python3.withPackages (p: [p.websockets]);
in
  stdenv.mkDerivation rec {
    pname = "wallpaper-engine-kde-plugin";
    version = "ed58dd8b920dbb2bf0859ab64e0b5939b8a32a0e";

    src = fetchFromGitHub {
      owner = "catsout";
      repo = pname;
      rev = version;
      hash = "sha256-ICQLtw+qaOMf0lkqKegp+Dkl7eUgPqKDn8Fj5Osb7eA=";
      fetchSubmodules = true;
    };

    patches = [./cmake.patch];

    cmakeFlags = [
      "-DQT_MAJOR_VERSION=6"
    ];

    nativeBuildInputs = [
      cmake
      qt6.wrapQtAppsHook
      kdePackages.extra-cmake-modules
      pkg-config
    ];

    propagatedBuildInputs =
      [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwebsockets
        qt6.qtwebchannel

        vulkan-headers
        mpv
        libass
        lz4
        fribidi
      ]
      ++ (with kdePackages; [
        libplasma
        kdeclarative
        qt5compat
        plasma5support
        kirigami
        kcoreaddons
      ]);
    strictDeps = true;

    postInstall = ''
      substituteInPlace $out/share/plasma/wallpapers/com.github.catsout.wallpaperEngineKde/contents/ui/Pyext.qml \
        --replace "/usr/share" "$out/share" \
        --replace "python3" "${pythonPath}/bin/python3"
    '';

    meta = with lib; {
      description = "A wallpaper plugin integrating wallpaper engine into kde wallpaper setting.";
      homepage = "https://github.com/catsout/wallpaper-engine-kde-plugin";
      license = licenses.gpl2;
    };
  }
