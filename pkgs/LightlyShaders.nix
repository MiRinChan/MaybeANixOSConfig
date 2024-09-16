# https://github.com/ericr35811/nixos-configs/hm/plasma-theme.nix
{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
  stdenv ? pkgs.stdenv,
  fetchFromGitHub ? pkgs.fetchFromGitHub,
  cmake ? pkgs.cmake,
}:
stdenv.mkDerivation rec {
  pname = "LightlyShaders";
  version = "9999";

  src = fetchFromGitHub {
    owner = "AldanTanneo";
    repo = pname;
    rev = "3ff2d2f";
    sha256 = "sha256-EBzzkLIuH7ST+LzeBnj6JXeYHGsmli4qupIe4oLGus0=";
  };

  buildInputs = with pkgs.kdePackages; [
    qtbase
    kconfig
    kconfigwidgets
    kcoreaddons
    kcrash
    kglobalaccel
    ki18n
    kio
    kservice
    knotifications
    kwidgetsaddons
    kwindowsystem
    kguiaddons
    kcmutils
    kwin
  ];

  nativeBuildInputs = [
    cmake
    pkgs.kdePackages.extra-cmake-modules
    pkgs.kdePackages.qttools
    pkgs.kdePackages.wrapQtAppsHook
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=/usr"
  ];

  postConfigure = ''
    echo --------------- cmake_install.cmake ---------------
    cat cmake_install.cmake
    # substituteInPlace cmake_install.cmake \
    #  --replace "" "$out"
  '';

  postInstall = ''
    echo "out: $out"
  '';
}
