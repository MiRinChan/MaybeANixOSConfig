{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
  python3,
  unzip,
}: let
  gallantSource = fetchFromGitHub {
    owner = "NanoBillion";
    repo = "gallant";
    rev = "a8bf79449bea4a17e577687c66b87df0444fbcf7";
    hash = "sha256-UL6pcjRZbVh+dknAXQBuYw1NWFKDeXAShCFtHtHFoMU=";
  };
  mapleSource = fetchFromGitHub {
    owner = "subframe7536";
    repo = "maple-font";
    rev = "dc9e19927e8e1d39a42095a43b00fc301adf3531";
    hash = "sha256-J8afiYodVBEWfUybsw98zzI/GWCAEYPxenufHOKmNA0=";
  };
  # These are the supplementary glyph inputs used by the upstream source build.
  nerdSymbols = fetchurl {
    url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/NerdFontsSymbolsOnly.zip";
    hash = "sha256-STYkUM1hsyx9Ha27mOgmltd8whU0RjbSXqvIqC1vjX8=";
  };
  mapleCN = fetchurl {
    url = "https://github.com/subframe7536/maple-font/releases/download/cn-base/cn-base-static.zip";
    hash = "sha256-HkBRGojXBoWnJ3q0ismVaav0GGuZj+hs0vOGbH8XYvs=";
  };
  python = python3.withPackages (ps: [ps.fonttools ps.pytest]);
in
  stdenvNoCC.mkDerivation {
    pname = "gallant-terminal-nerd";
    version = "0.2.0";

    src = fetchFromGitHub {
      owner = "MiRinChan";
      repo = "gallant-terminal-font";
      rev = "c63455b90d22ee50ee77adf52238c3e15b36f607";
      hash = "sha256-C+YM2CPhTjHdU5iDV1g/HF6yixlHy5CO4Gr3hTcBiSw=";
    };

    patches = [./merge-pixel-contours.patch];

    nativeBuildInputs = [python unzip];
    dontConfigure = true;
    preferLocalBuild = true;
    allowSubstitutes = false;

    postUnpack = ''
      cp -r ${gallantSource}/. "$sourceRoot/vendor/gallant/"
    '';

    buildPhase = ''
      runHook preBuild

      export PYTHONPATH="$PWD/src"
      export gallant_SOURCES="$PWD/sources"
      mkdir -p sources
      unzip -j ${nerdSymbols} SymbolsNerdFont-Regular.ttf LICENSE -d sources
      unzip -j ${mapleCN} MapleMonoCN-Regular.ttf -d sources

      python -m gallant_terminal.build \
        --source vendor/gallant/gallant.bdf \
        --output dist/gallantTerminal-Regular.ttf
      python -m gallant_terminal.merge \
        --base dist/gallantTerminal-Regular.ttf \
        --nerd sources/SymbolsNerdFont-Regular.ttf \
        --maple sources/MapleMonoCN-Regular.ttf \
        --output dist/gallantTerminalNerd-Regular.ttf

      runHook postBuild
    '';

    doCheck = true;
    checkPhase = ''
      runHook preCheck

      pytest -q
      python -m gallant_terminal.verify dist

      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall

      install -Dm444 dist/gallantTerminalNerd-Regular.ttf \
        "$out/share/fonts/truetype/gallant-terminal-nerd/gallantTerminalNerd-Regular.ttf"
      install -Dm444 -t "$out/share/doc/gallant-terminal-nerd" \
        vendor/gallant/LICENSE vendor/gallant/LICENSE.FreeBSD vendor/gallant/Contributors.md
      install -Dm444 sources/LICENSE "$out/share/doc/gallant-terminal-nerd/NerdFonts-LICENSE"
      install -Dm444 ${mapleSource}/OFL.txt "$out/share/doc/gallant-terminal-nerd/MapleMono-LICENSE.txt"

      runHook postInstall
    '';

    meta = {
      description = "Gallant terminal font built from BDF with Nerd Symbols and Maple CN glyphs";
      homepage = "https://github.com/MiRinChan/gallant-terminal-font";
      license = with lib.licenses; [bsd2 mit ofl];
      platforms = lib.platforms.all;
    };
  }
