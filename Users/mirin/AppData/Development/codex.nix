{pkgs, ...}: let
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
  # Keep MCP server commands declarative so their Nix store paths follow
  # package updates. Codex settings, authentication, and skills stay local.
  programs.mcp = {
    enable = true;
    servers.nixos.command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    servers.git.command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
  };

  home.packages = [
    codexGuiSudo
    pkgs.llm-agents.codex
    pkgs.mcp-nixos
    pkgs.mcp-server-git
  ];
}
