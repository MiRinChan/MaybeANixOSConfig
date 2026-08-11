{pkgs, ...}: let
  # The NUR derivation rebuilds the bundled TTF and currently fails on this
  # nixpkgs snapshot, so reuse upstream's generated TTF for font installation.
  gallantFont = pkgs.nur.repos.prince213.gallant.overrideAttrs (_: {
    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';
  });
  gallantConsoleFont =
    pkgs.runCommand "${gallantFont.pname}-console-font-${gallantFont.version}" {
      nativeBuildInputs = [pkgs.bdf2psf];
    } ''
      mkdir -p "$out/share/consolefonts"
      cd ${pkgs.bdf2psf}/share/bdf2psf
      bdf2psf \
        --fb "${gallantFont.src}/gallant.bdf" \
        standard.equivalents \
        ascii.set+useful.set+linux.set \
        512 \
        "$out/share/consolefonts/gallant.psfu"
    '';
in {
  nixpkgs.config.problems.handlers.gallant.broken = "warn";

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      maple-mono.NF-CN
      monaspace
      sarasa-gothic
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      source-han-mono
      source-han-sans
      source-han-serif
      gallantFont
    ];
    fontconfig = {
      enable = true;
      # 默认字体
      defaultFonts = {
        monospace = [
          "Maple Mono NF CN Medium"
          "FiraCode Nerd Font Mono"
          "Source Han Mono SC"
          "Source Han Mono"
          "Noto Sans Mono CJK SC"
          "Noto Sans Mono CJK"
          "Noto Sans Mono"
        ];
        sansSerif = [
          "Source Han Sans SC"
          "Source Han Sans"
          "Noto Sans CJK SC"
          "Noto Sans CJK"
          "Noto Sans"
        ];
        serif = [
          "Source Han Serif SC"
          "Source Han Serif"
          "Noto Serif CJK SC"
          "Noto Serif CJK"
          "Noto Serif"
        ];
        emoji = ["Noto Color Emoji"];
      };
      localConf = ''
        <!-- Make Emoji happy. -->
        <match target="font">
          <test name="family" qual="first">
            <string>Noto Color Emoji</string>
          </test>
          <edit mode="assign" name="antialias">
            <bool>false</bool>
          </edit>
        </match>
      '';
    };
  };

  console = {
    packages = [gallantConsoleFont];
    font = "${gallantConsoleFont}/share/consolefonts/gallant.psfu";
    earlySetup = true;
    keyMap = "us";
  };
}
