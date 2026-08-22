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

  pi-effort = copyExt {
    pname = "pi-effort";
    version = "0.0.8";
    src = npmTgz "pi-effort" "0.0.8" "sha256-ByXtDJ42T3t6A0kp6IhdD6jdI3zK4Q65H10OSuElB2s=";
  };

  pi-oh-pi-skills = copyExt {
    pname = "pi-oh-pi-skills";
    version = "0.5.1";
    src = npmTgz "@ifi/oh-pi-skills" "0.5.1" "sha256-56eElx0pSUyew5n3qb17yNAyeiL9KB3esJ5871QOTyQ=";
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
  pi-hashline-edit-pro = buildNpmPackage {
    pname = "pi-hashline-edit-pro";
    version = "2.6.1";
    src = npmTgz "pi-hashline-edit-pro" "2.6.1" "sha256-Jc6RpcLxdYkrdLmzNcSx1WzIodY+PNNFgorZMq4XWks=";
    postPatch = ''
      cp ${./patched/pi-hashline-edit-pro.json} ./package.json
      cp ${./locks/pi-hashline-edit-pro.lock} ./package-lock.json
      sed -i '/const db = new DatabaseSync(storePath, {/,+2c\\  const db = new DatabaseSync(storePath);' src/hash-store.ts
      substituteInPlace src/hash-store.ts \
        --replace-fail 'import { DatabaseSync } from "node:sqlite";' 'import { Database as DatabaseSync } from "bun:sqlite";' \
        --replace-fail 'cachedDb.db.isOpen' '(cachedDb.db.isOpen ?? true)'
    '';
    npmDepsHash = "sha256-MpVG71Vxg4PQ50WVzUJ43TeJmJzk03yOvYlYlIubWIs=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };

  pi-lens = buildNpmPackage {
    pname = "pi-lens";
    version = "4.1.0";
    src = npmTgz "pi-lens" "4.1.0" "sha256-AebgyImomtLgNwqt9Frb3lcqoKdhJ+rRDl4jkrw6M6U=";
    postPatch = ''
      cp ${./patched/pi-lens.json} ./package.json
      cp ${./locks/pi-lens.lock} ./package-lock.json
    '';
    npmDepsHash = "sha256-I5rs6gSk4gvZ7LXPObvvSQRvVyDeTqzi0PecVbIez70=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };

  pi-memory = copyExt {
    pname = "pi-memory";
    version = "0.4.2";
    src = npmTgz "pi-memory" "0.4.2" "sha256-rEgmpLFrt16BhxqkzKzLdwH9CcvX7Wv3ha2ZvTymDj8=";
  };

  pi-lean-portal = buildNpmPackage {
    pname = "pi-lean-portal";
    version = "0.4.0";
    src = npmTgz "pi-lean-portal" "0.4.0" "sha256-4aUubi0jrwLbY7ywGjWwrGeCXrQf+0/teH1sENtBTQw=";
    postPatch = ''
      cp ${./patched/pi-lean-portal.json} ./package.json
      cp ${./locks/pi-lean-portal.lock} ./package-lock.json
    '';
    npmDepsHash = "sha256-KivCt0AUNp1G1WVLTs2n4h6OCJDWZT/Q6QPRjwY4VGI=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };

  pi-plan = buildNpmPackage {
    pname = "pi-plan";
    version = "0.5.1";
    src = npmTgz "@ifi/pi-plan" "0.5.1" "sha256-3z+mMUF9VpVScSt7ukrqvvwbsuEIBoVQH+2fwBZd+KI=";
    postPatch = ''
      cp ${./patched/pi-plan.json} ./package.json
      cp ${./locks/pi-plan.lock} ./package-lock.json
    '';
    npmDepsHash = "sha256-yfqTra5tBPesrUaryAeC+1LdrYm6H91iKL9y8rlZCpw=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
    postInstall = ''
      substituteInPlace $out/node_modules/@ifi/pi-shared-qna/pi-tui-loader.ts \
        --replace-fail 'import { createRequire } from "node:module";' "import * as nixPiTui from \"$out/node_modules/@mariozechner/pi-tui/dist/index.js\";" \
        --replace-fail 'const requireFn = options.requireFn ?? createRequire(import.meta.url);' $'if (!options.requireFn) return nixPiTui;\n\tconst requireFn = options.requireFn;'
    '';
  };

  pi-background-tasks = buildNpmPackage {
    pname = "pi-background-tasks";
    version = "2.4.2";
    src = npmTgz "pi-background-tasks" "2.4.2" "sha256-jVFZG0NDGH3DgSV228fGvqlkoLzGWkw3jz+zjcEdhXE=";
    postPatch = ''
      cp ${./patched/pi-background-tasks.json} ./package.json
      cp ${./locks/pi-background-tasks.lock} ./package-lock.json
    '';
    npmDepsHash = "sha256-udsz8Romz6CL1pxmnWQns4xxkrK4V3la3qGv2dLRzbo=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };

  pi-oh-pi-ant-colony = buildNpmPackage {
    pname = "pi-oh-pi-ant-colony";
    version = "0.5.1";
    src = npmTgz "@ifi/oh-pi-ant-colony" "0.5.1" "sha256-GxQTeGh1G7B7ZzggBSGx9q3WHKlgcIclTU7Ir7BcbWw=";
    postPatch = ''
      cp ${./locks/pi-oh-pi-ant-colony.lock} ./package-lock.json
    '';
    npmDepsHash = "sha256-W/ZLFmTXQ4RVJjFR5gzpDbb8fUhp69TXWTsnGg3GyLE=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };

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
    npmDepsHash = "sha256-okY+1QAnAojysshi22emKIlrUu1+ghtYa9rdB3ikNy4=";
    npmInstallFlags = ["--ignore-scripts"];
    dontNpmBuild = true;
    installPhase = extInstallPhase;
  };
}
