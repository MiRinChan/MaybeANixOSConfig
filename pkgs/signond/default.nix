{
  stdenv,
  lib,
  fetchFromGitLab,
  qmake,
  qtbase,
  wrapQtAppsHook,
  doxygen,
  withOAuth2 ? false,
  signon-plugin-oauth2,
  withKWallet ? false,
  signon-kwallet-extension,
  makeWrapper,
  symlinkJoin
}:

let
  unwrapped = stdenv.mkDerivation rec {
    pname = "signond";
    version = "8.61-unstable-2023-11-24";

    outputs = [ "out" ];

    # pinned to fork with Qt6 support
    src = fetchFromGitLab {
      owner = "nicolasfella";
      repo = "signond";
      rev = "c8ad98249af541514ff7a81634d3295e712f1a39";
      hash = "sha256-0FcSVF6cPuFEU9h7JIbanoosW/B4rQhFPOq7iBaOdKw=";
    };

    nativeBuildInputs = [
      qmake
      doxygen
      wrapQtAppsHook
    ];

    buildInputs = [ qtbase ]
      ++ lib.optional withOAuth2 signon-plugin-oauth2
      ++ lib.optional withKWallet signon-kwallet-extension;

    preConfigure = ''
      substituteInPlace src/signond/signond.pro \
        --replace "/etc" "@out@/etc"
    '';

    meta = with lib; {
      homepage = "https://gitlab.com/accounts-sso/signond";
      description = "Signon Daemon for Qt";
      maintainers = with maintainers; [ freezeboy ];
      platforms = platforms.linux;
    };
  };
in if (!withOAuth2 && !withKWallet) then unwrapped
   else import ./wrapper.nix {
     inherit lib symlinkJoin withOAuth2 signon-plugin-oauth2 withKWallet signon-kwallet-extension makeWrapper;
     signond = unwrapped;
   }
