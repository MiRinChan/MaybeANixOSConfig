{
  stdenv,
  lib,
  fetchFromGitLab,
  qmake,
  pkg-config,
  qtbase,
  signond,
  wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "signon-plugin-oauth2";
  version = "0.25-unstable-2023-10-15";

  # pinned to fork with Qt6 support
  src = fetchFromGitLab {
    owner = "nicolasfella";
    repo = "signon-plugin-oauth2";
    rev = "fab698862466994a8fdc9aa335c87b4f05430ce6";
    hash = "sha256-KCBLaqQdBkb6KfVKMmFSLOiXx3rUiEmK41Bc3mi86Ls=";
  };

  nativeBuildInputs = [
    qmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    signond
  ];

  qmakeFlags = [
    "INSTALL_PREFIX=${placeholder "out"}"
    "SIGNON_PLUGINS_DIR=${placeholder "out"}/lib/signon"
  ];

  meta = with lib; {
    description = "Signond OAuth 1.0/2.0 plugin";
    homepage = "https://gitlab.com/accounts-sso/signon-plugin-oauth2";
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}
