# Pi coding agent extensions and tools, packaged from npm / GitHub.
# Dependencies are resolved at runtime by pi itself (peer deps) or bundled
# into node_modules via buildNpmPackage.
{pkgs}: let
  inherit (pkgs) buildNpmPackage fetchurl fetchFromGitHub stdenvNoCC;
  inherit (pkgs.lib) licenses;

  # An extension whose only dependencies are peer deps provided by pi itself.
  copyExt = {
    pname,
    version,
    src,
  }:
    stdenvNoCC.mkDerivation {
      inherit pname version src;
      dontConfigure = true;
      dontBuild = true;
      dontFixup = true;
      installPhase = ''
        mkdir -p $out
        cp -a . $out/
      '';
    };

  npmTgz = pkg: version: hash:
    fetchurl {
      url = "https://registry.npmjs.org/${pkg}/-/${builtins.baseNameOf pkg}-${version}.tgz";
      inherit hash;
    };

  # Uniform layout for npm-built pi extensions: source files + node_modules at
  # $out root, so the extension entry is always ${ext}/<relative-entry>.
  extInstallPhase = ''
    runHook preInstall
    mkdir -p $out
    find . -maxdepth 1 -mindepth 1 ! -name node_modules -exec cp -a {} $out/ \;
    cp -a node_modules $out/
    runHook postInstall
  '';
in {
  # --- extensions without runtime deps (source only) ---
  pi-preferred-thinking = copyExt {
    pname = "pi-preferred-thinking";
    version = "0.3.0";
    src = npmTgz "@tifan/pi-preferred-thinking" "0.3.0" "sha256-v6fJOXfK/rJYrJ7hBxeJ8PDLEHVpbb5MoB8Vpii7ZEI=";
  };

  pi-rtk-optimizer = copyExt {
    pname = "pi-rtk-optimizer";
    version = "0.9.0";
    src = npmTgz "pi-rtk-optimizer" "0.9.0" "sha256-T3xtmO2QqZne7ntaT4MVvQ/Rf5nSECKw0LZPd7wR08g=";
  };

  pi-observational-memory = copyExt {
    pname = "pi-observational-memory";
    version = "3.0.4";
    src = npmTgz "pi-observational-memory" "3.0.4" "sha256-rydBxtZfPWhz7QXQRY7K1omwGhZgD98aZQujAbR9d1Y=";
  };

  pi-jingle = copyExt {
    pname = "pi-jingle";
    version = "1.1.1";
    src = npmTgz "pi-jingle" "1.1.1" "sha256-WwgdWvrzma3PPn6FWuGUuZA6+84bPF4ddwQxKhEBMuo=";
  };

  pi-context-usage = copyExt {
    pname = "pi-context-usage";
    version = "1.0.2";
    src = fetchFromGitHub {
      owner = "championswimmer";
      repo = "pi-context-usage";
      rev = "aa1a0150c2d5420f7c64c5e177630baab70e927a";
      hash = "sha256-FU9y5DAZlylm1LUFhUo850vR56lMOJ6T60txSHFj3iU=";
    };
  };

  pi-btw = copyExt {
    pname = "pi-btw";
    version = "0.4.1";
    src = fetchFromGitHub {
      owner = "dbachelder";
      repo = "pi-btw";
      rev = "4f858102706910ee9d520a9666832f3103631b61";
      hash = "sha256-tXcZUh20xYUTn80cubpd9BjFPAcLQK7CrEKxTnsdQ2s=";
    };
  };

  # --- extensions with runtime dependencies (npm build) ---
  pi-mcp-adapter = buildNpmPackage {
    pname = "pi-mcp-adapter";
    version = "2.26.0";
    src = npmTgz "pi-mcp-adapter" "2.26.0" "sha256-1hfsccXd3a3vqUZzczw/wwYNYDgaoMk7HAArCNnRjAk=";
    postPatch = ''
      cp ${./patched/pi-mcp-adapter.json} ./package.json
      cp ${./locks/pi-mcp-adapter.lock} ./package-lock.json
    '';
    npmDepsHash = "sha256-KvOmPTLQzLYj+VLhHxghthejupiw5sR5dnseh98o9U8=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };

  rpiv-ask-user-question = buildNpmPackage {
    pname = "rpiv-ask-user-question";
    version = "2.6.0";
    src = npmTgz "@juicesharp/rpiv-ask-user-question" "2.6.0" "sha256-tdzrkAqu9Bvpm6ZSW6kxdsgpu26AzdZY/Rr/iVJ4gJ0=";
    postPatch = ''
      cp ${./patched/rpiv-ask-user-question.json} ./package.json
      cp ${./locks/rpiv-ask-user-question.lock} ./package-lock.json
    '';
    npmDepsHash = "sha256-PNkAAFPfxnIeon6ho4bkGPO5zrgENxwAiUL0hkTQlCc=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };

  pi-workspace-history = buildNpmPackage {
    pname = "pi-workspace-history";
    version = "0.2.2";
    src = fetchFromGitHub {
      owner = "wcldyx";
      repo = "pi-workspace-history";
      rev = "ec9bb41cdab9fb6891ffebbc2f5c73751d23f5b8";
      hash = "sha256-CAK2nNB67F+mdnCa74Y37/TOHJTVtbC1n46KLtemsLI=";
    };
    npmDepsHash = "sha256-dgjdPIU341wdxABTSAQXptmgQfkRCR9n6UeM44jkgwQ=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };

  # DuckDuckGo MCP server (spawned as an MCP server, not a pi extension).
  duckduckgo-mcp-server = buildNpmPackage {
    pname = "duckduckgo-mcp-server";
    version = "0.6.0";
    src = npmTgz "@ericthered926/duckduckgo-mcp-server" "0.6.0" "sha256-UemfYS788EBSmWFDXkl7ukzuOUqUhN3nUZk4HOIaEnA=";
    postPatch = ''
      cp ${./patched/duckduckgo-mcp-server.json} ./package.json
      cp ${./locks/duckduckgo-mcp-server.lock} ./package-lock.json
    '';
    npmInstallFlags = ["--ignore-scripts"];
    npmDepsHash = "sha256-riNZjVjdu546W3VHPBCRYUiOMiTTy7IL45IEShcvuyU=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r build $out/build
      cp -r node_modules $out/node_modules
      runHook postInstall
    '';
  };

  # Codex 式自动审批：模型按风险策略评估每个操作，安全自动放行，危险才问用户。
  pi-permission-auto-review = buildNpmPackage {
    pname = "pi-permission-auto-review";
    version = "0.2.0";
    src = npmTgz "@mzwing/pi-permission-auto-review" "0.2.0" "sha256-HSnuPgt61iphs+U6/1b/KhAo1KGdZFVrqYFan7kFe04=";
    postPatch = ''
      cp ${./patched/pi-permission-auto-review.json} ./package.json
      cp ${./locks/pi-permission-auto-review.lock} ./package-lock.json
    '';
    npmInstallFlags = ["--ignore-scripts"];
    npmDepsHash = "sha256-0vR2hdtw0l2mPC6g4x2ptR9ZJ8bxeog5bY2vLyDgejo=";
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };

  # FFF-powered find/grep (ships a native C FFI addon via @ff-labs/fff-node).
  pi-fff = buildNpmPackage {
    pname = "pi-fff";
    version = "0.5.0";
    src = fetchFromGitHub {
      owner = "sanurb";
      repo = "pi-fff";
      rev = "3c936f9b411e27cbf1a5d1573e3fe5f173a09706";
      hash = "sha256-2nZlVmJWSidQTSlRWkBWwm3DOTyPNIXUBg6PtWbgumA=";
    };
    postPatch = ''
      cp ${./patched/pi-fff.json} ./package.json
      cp ${./locks/pi-fff.lock} ./package-lock.json
    '';
    npmDepsHash = "sha256-wQ+tS/cKEA0eAHrn4lYBWcbJc3oCh1HPHkDYBPoJKk4=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };
}
