# from: https://github.com/flyingcircusio/nixpkgs/blob/28b740864b4e68f6a72bc35129d28ede5b273e62/pkgs/by-name/lu/lunar-client/package.nix

{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
}:

appimageTools.wrapType2 rec {
  pname = "lunar-client";
  version = "3.3.2";

  src = fetchurl {
    url = "https://launcherupdates.lunarclientcdn.com/Lunar%20Client-${version}.AppImage";
    hash = "sha512-Gpm17h5U9Cw9r5EHE1wF5e0aza9yaGPUf+rhMVAhXjrVYBqiUsc/UG11TXWqarKlLpRmPDe+BvCF0qqTtTEZhw==";
  };

  extraInstallCommands =
    let
      contents = appimageTools.extract { inherit pname version src; };
    in
    ''
      source "${makeWrapper}/nix-support/setup-hook"
      wrapProgram $out/bin/lunar-client \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
      install -Dm444 ${contents}/lunarclient.desktop $out/share/applications/lunar-client.desktop
      install -Dm444 ${contents}/lunarclient.png $out/share/pixmaps/lunar-client.png
      substituteInPlace $out/share/applications/lunar-client.desktop \
        --replace 'Exec=AppRun --no-sandbox %U' 'Exec=lunar-client' \
        --replace 'Icon=launcher' 'Icon=lunar-client'
    '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Free Minecraft client with mods, cosmetics, and performance boost.";
    homepage = "https://www.lunarclient.com/";
    license = with licenses; [ unfree ];
    mainProgram = "lunar-client";
    maintainers = with maintainers; [
      zyansheep
      Technical27
      surfaceflinger
    ];
    platforms = [ "x86_64-linux" ];
  };
}
