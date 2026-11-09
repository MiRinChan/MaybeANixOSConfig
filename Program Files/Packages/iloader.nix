{
  appimageTools,
  fetchurl,
}:
appimageTools.wrapType2 rec {
  pname = "iloader";
  version = "2.3.6";

  src = fetchurl {
    url = "https://github.com/nab138/iloader/releases/download/v${version}/iloader-linux-amd64.AppImage";
    hash = "sha256-X2yOjb/Jq3VSYgDVo1iKe6dx6HPvIX8f8UsSw46StY8=";
  };

  extraInstallCommands = let
    contents = appimageTools.extract {inherit pname version src;};
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
