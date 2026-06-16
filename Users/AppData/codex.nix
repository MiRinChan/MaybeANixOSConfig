{
  config,
  lib,
  pkgs,
  ...
}: let
  codexSettings = {
    features.memories = true;
    memories.no_memories_if_mcp_or_web_search = true;
    mcp_servers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      enabled = true;
    };
    mcp_servers.git = {
      command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
      enabled = true;
    };
  };
  codexDefaultConfig = (pkgs.formats.toml {}).generate "codex-config-default" codexSettings;
  codexHome = "${config.home.homeDirectory}/.codex";
  codexGuiSudo = pkgs.writeShellScriptBin "codex-gui-sudo" ''
    set -euo pipefail

    if [ "$#" -eq 0 ]; then
      echo "usage: codex-gui-sudo [--shell COMMAND | COMMAND ARG...]" >&2
      exit 2
    fi

    if [ "$1" = "--shell" ]; then
      shift
      if [ "$#" -eq 0 ]; then
        echo "codex-gui-sudo: --shell requires a command" >&2
        exit 2
      fi
      command_text="$*"
      run_script="cd $(printf '%q' "$PWD") && $command_text"
    else
      quoted=()
      for arg in "$@"; do
        quoted+=("$(printf '%q' "$arg")")
      done
      command_text="''${quoted[*]}"
      run_script="cd $(printf '%q' "$PWD") && exec $command_text"
    fi

    message=$(printf 'Codex wants to run this command as root:\n\n%s\n\nWorking directory:\n%s' "$command_text" "$PWD")
    ${pkgs.kdePackages.kdialog}/bin/kdialog \
      --title "Codex privileged command" \
      --warningcontinuecancel "$message"

    exec /run/wrappers/bin/pkexec ${pkgs.bash}/bin/bash -lc "$run_script"
  '';
in {
  programs.mcp = {
    enable = true;
    servers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    };
    servers.git = {
      command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
    };
  };

  programs.codex = {
    enable = true;
    enableMcpIntegration = false;
    skills.nixos = "${pkgs.fetchFromGitHub {
      owner = "marceloeatworld";
      repo = "nixos-ai-skill";
      rev = "922573e59bcd8eef7e9a7a5f9b40a28812d39357";
      sha256 = "125agnm8kmvg3rr3a07lwp9dfdyxki2s2q4rm8y8v2qrc03iimb5";
    }}";
  };

  home.packages = [
    codexGuiSudo
    pkgs.mcp-nixos
    pkgs.mcp-server-git
  ];

  home.file.".codex/config.defaults.toml".source = codexDefaultConfig;

  home.activation.initWritableCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_file="${codexHome}/config.toml"
    defaults="${codexHome}/config.defaults.toml"

    mkdir -p "${codexHome}"

    if [ ! -e "$config_file" ] || [ -L "$config_file" ]; then
      rm -f "$config_file"
      cp "$defaults" "$config_file"
      chmod 600 "$config_file"
    fi
  '';
}
