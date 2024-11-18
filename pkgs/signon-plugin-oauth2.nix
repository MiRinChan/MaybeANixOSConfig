{
  lib,
  fetchFromGitLab,
  qtbase,
  stdenv,
  wrapQtAppsHook,
  signond,
  pkg-config,
  qmake,
}:
stdenv.mkDerivation rec {
  pname = "signon-plugin-oauth2";
  version = "0.25";

  src = fetchFromGitLab {
    owner = "accounts-sso";
    repo = pname;
    # Use a later commit than 0.25, as this disabled -Werror and prevents us from needing to patch.
    rev = "d759439066f0a34e5ad352ebab0b3bb2790d429e";
    sha256 = "sha256-4oyfxksatR/xZT7UvECfo3je3A77+XOnhTIrxBCEH2c=";
  };

  buildInputs = [
    qtbase
    signond
  ];

  nativeBuildInputs = [
    wrapQtAppsHook
    pkg-config
    qmake
  ];

  INSTALL_ROOT = "$out";
  SIGNON_PLUGINS_DIR = "${placeholder "out"}/lib/signond/plugins";

  meta = with lib; {
    homepage = "https://gitlab.com/accounts-sso/signon-plugin-oauth2";
    description = "OAuth 1.0/2.0 plugin for the SignOn daemon";
    maintainers = with maintainers; [];
    platforms = platforms.linux;
  };
}
