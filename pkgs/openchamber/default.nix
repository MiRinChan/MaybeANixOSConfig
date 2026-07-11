{
  lib,
  callPackage,
  fetchFromGitHub,
}: let
  version = "1.15.0";
  src = fetchFromGitHub {
    owner = "openchamber";
    repo = "openchamber";
    rev = "5127f5c889204a21eea7904cc5686452b807a9fa";
    hash = "sha256-UtOkKJ8vZSdVK/wu5MKJc0YWShF/KI0jq+G+6b8mm1o=";
  };
  bunDeps = callPackage ./bun-deps.nix {
    inherit src version;
  };
in {
  cli = callPackage ./cli.nix {
    inherit bunDeps src version;
  };
  desktop = callPackage ./desktop.nix {
    inherit bunDeps src version;
  };
}
