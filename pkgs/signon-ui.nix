{
  stdenv,
  lib,
  fetchFromGitLab,
  qmake,
  pkg-config,
  qtbase,
  qtwebengine,
  qtdeclarative,
  accounts-qt,
  libnotify,
  libproxy,
  signond,
  wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "signon-ui";
  version = "0.17-unstable-2023-10-16";

  src = fetchFromGitLab {
    owner = "accounts-sso";
    repo = "signon-ui";
    rev = "eef943f0edf3beee8ecb85d4a9dae3656002fc24";
    hash = "sha256-L37nypdrfg3ZGZE4uGtFoJlzNbFgTVgA36zCgzvzk6E=";
  };

  nativeBuildInputs = [
    qmake
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtwebengine
    qtdeclarative
    accounts-qt
    libnotify
    libproxy
    signond
  ];

  patches = [
    # fake user ID taken from Arch
    ./fake-user-agent.patch
  ];

  meta = with lib; {
    description = "Signond Qt UI";
    homepage = "https://gitlab.com/accounts-sso/signon-ui";
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}
