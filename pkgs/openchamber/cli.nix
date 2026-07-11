{
  stdenvNoCC,
  src,
  version,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "openchamber-bootstrap";
  inherit src version;
  dontBuild = true;
  installPhase = "mkdir -p $out";
}
