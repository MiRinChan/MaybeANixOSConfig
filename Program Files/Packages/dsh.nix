{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  runCommand,
  makeWrapper,
  versionCheckHook,
}: let
  version = "0.1.0-rc.6";

  srcWithLock = runCommand "dsh-source" {} ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-${version}.tgz";
        hash = "sha512-brpZfED7ieRa2PQ5tUxMhHrM1pb2CmKFVM/f6yMULBDMicahk+Z2OsHgTwTDnoiZm23Ftu9rQz0NN4pflaoJcg==";
      }
    } -C $out --strip-components=1
    cp ${./dsh/package-lock.json} $out/package-lock.json
  '';
in
  buildNpmPackage {
    pname = "dsh";
    inherit version;
    src = srcWithLock;

    nodejs = nodejs_22;
    npmDepsFetcherVersion = 2;
    npmDepsHash = "sha256-63LcvleBc/WdvfDow+YMTljpmY2WgMLTo6SMIdOpKWA=";

    # The npm package already contains the compiled CLI files.
    dontNpmBuild = true;

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      npm prune --omit=dev

      mkdir -p $out/lib/dsh $out/bin
      cp -r lib config package.json README* node_modules $out/lib/dsh/

      makeWrapper ${lib.getExe nodejs_22} $out/bin/dsh \
        --add-flags "$out/lib/dsh/lib/bin.js"

      runHook postInstall
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [versionCheckHook];
    versionCheckProgramArg = ["--version"];

    meta = with lib; {
      description = "Open-source agent harness developed by DeepSeek AI";
      homepage = "https://github.com/deepseek-ai/deepseek-harness";
      changelog = "https://github.com/deepseek-ai/deepseek-harness/releases";
      license = licenses.mit;
      sourceProvenance = with sourceTypes; [binaryBytecode];
      mainProgram = "dsh";
      platforms = platforms.unix;
    };
  }
