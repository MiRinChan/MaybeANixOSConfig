{pkgs, ...}:
pkgs.appimageTools.wrapType2 rec {
  pname = "iloader";
  version = "2.2.4";

  src = pkgs.fetchurl {
    url = "https://github.com/nab138/iloader/releases/download/v${version}/iloader-linux-amd64.AppImage";
    hash = "sha256-Dkcb4LzhhVMaHZww1TQcE/NrdiYahRUjwGCxI4xGZc8=";
  };

  extraInstallCommands = let
    contents = pkgs.appimageTools.extractType2 {inherit pname version src;};
  in ''
    mkdir -p "$out/share/applications"
    cp --no-preserve=ownership,mode -r ${contents}/usr/share/* "$out/share"
    cp --no-preserve=ownership,mode "${contents}/${pname}.desktop" "$out/share/applications/"
    substituteInPlace $out/share/applications/${pname}.desktop --replace-fail 'Exec=iloader' 'Exec=${meta.mainProgram}'
  '';

  meta = {
    mainProgram = "iloader";
  };
}
