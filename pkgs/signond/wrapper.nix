{
  lib,
  symlinkJoin,
  signond,
  withOAuth2,
  signon-plugin-oauth2,
  withKWallet,
  signon-kwallet-extension,
  makeWrapper
}:

symlinkJoin {
  name = "signond-with-plugins-${signond.version}";

  paths = [ signond ]
    ++ lib.optional withOAuth2 signon-plugin-oauth2
    ++ lib.optional withKWallet signon-kwallet-extension;

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/signond \
      ${lib.optionalString withOAuth2 "--set SSO_PLUGINS_DIR \"$out/lib/signon\""} \
      ${lib.optionalString withKWallet "--set SSO_EXTENSIONS_DIR \"$out/lib/extensions\""}

    rm $out/share/dbus-1/services/com.google.code.AccountsSSO.SingleSignOn.service

    substitute ${signond}/share/dbus-1/services/com.google.code.AccountsSSO.SingleSignOn.service $out/share/dbus-1/services/com.google.code.AccountsSSO.SingleSignOn.service \
      --replace ${signond} $out
  '';

  inherit (signond) meta;
}
