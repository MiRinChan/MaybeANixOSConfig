{
  lib,
  buildGoModule,
  buildNpmPackage,
  libqmi,
}: let
  version = "1.6.0";
  revision = "d96df01a4f6fa8cc6660e018c26676e42435943d";
  src = ../vendor/vohive/vohive-next-1.6.0-d96df01.tar.gz;

  webui = buildNpmPackage {
    pname = "vohive-next-web";
    inherit version src;

    sourceRoot = "vohive-next/web";
    patches = [./vohive-disable-uninstall-frontend.patch];
    npmDepsHash = "sha256-bnU4VQGVXPAyTEQjETgtj9SHzR4d+oF5O971RVfkDbY=";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -R dist/. "$out/"
      runHook postInstall
    '';
  };
in
  buildGoModule {
    pname = "vohive-next";
    inherit version src;

    sourceRoot = "vohive-next";
    patches = [
      ./vohive-disable-uninstall-backend.patch
      ./vohive-nixos-qmi-proxy.patch
    ];
    vendorHash = "sha256-TamCszS0ATuOu6HSkWk88pFuPf391d8ReZT6VcUv1W4=";

    # The original iniwex5 repositories were removed. Pin the unchanged module
    # paths to the public forks and tags used by the source mirror's CI.
    postPatch = ''
      substituteInPlace internal/qmi/client_options.go \
        --replace-fail '@nixosQMIProxyExecutable@' '${libqmi}/libexec/qmi-proxy'

      go mod edit -replace=github.com/iniwex5/netlink=github.com/voorz/netlink@v1.3.3
      go mod edit -replace=github.com/iniwex5/qqbot=github.com/voorz/qqbot@v1.0.1
      go mod edit -replace=github.com/iniwex5/quectel-qmi-go=github.com/voorz/quectel-qmi-go@v0.6.0
      go mod edit -replace=github.com/iniwex5/vowifi-go=github.com/voorz/vowifi-go@v1.1.2
    '';

    env = {
      GOPROXY = "direct";
      GONOSUMDB = "github.com/voorz/*";
    };

    # The mirror updates the replacement module checksums during its build.
    # Reproduce that step before creating Nix's immutable vendor tree.
    modBuildPhase = ''
      runHook preBuild
      go mod tidy
      go mod vendor
      runHook postBuild
    '';

    preBuild = ''
      rm -rf internal/web/dist
      mkdir -p internal/web/dist
      cp -R ${webui}/. internal/web/dist/
    '';

    subPackages = ["cmd/vohive"];
    tags = [
      "with_utls"
      "nomsgpack"
    ];
    ldflags = [
      "-s"
      "-w"
      "-X github.com/iniwex5/vohive/internal/global.Version=${version}"
      "-X github.com/iniwex5/vohive/internal/global.BuildTime=2026-07-23T04:24:14Z"
    ];

    checkPhase = ''
      runHook preCheck
      mapfile -t packages < <(
        go list ./... |
          grep -v '^github.com/iniwex5/vohive/internal/config$' |
          grep -v '^github.com/iniwex5/vohive/internal/websheet$'
      )
      go test "''${packages[@]}"
      go test ./internal/config -skip '^TestMigrateDeprecatedRuntimePathFieldsScrubsDisk$'
      go test ./internal/websheet -skip '^(TestCreateAllowsPublicHTTPS|TestSessionExpires)$'
      runHook postCheck
    '';

    postInstall = ''
      mv "$out/bin/vohive" "$out/bin/vo-hive"
    '';

    meta = {
      description = "Unified management and proxy platform for Qualcomm modems";
      homepage = "https://github.com/FaLao2011/vohive-next";
      license = lib.licenses.unfreeRedistributable;
      mainProgram = "vo-hive";
      platforms = lib.platforms.linux;
      sourceProvenance = [lib.sourceTypes.fromSource];
    };

    passthru = {
      inherit revision webui;
    };
  }
