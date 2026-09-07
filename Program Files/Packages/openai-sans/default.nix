{
  lib,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "openai-sans";
  version = "2025-01-24";

  src = ./OpenAI-Sans-2025-01-24.zip;

  nativeBuildInputs = [unzip];

  unpackPhase = "unzip -qq $src";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm444 -t "$out/share/fonts/opentype/openai-sans" "OpenAI Sans/OT"/*.otf

    runHook postInstall
  '';

  meta = {
    description = "OpenAI Sans typeface";
    homepage = "https://openai.com/brand/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
})
