{
  inputs,
  lib,
  pkgs,
  ...
}: let
  codexBin = inputs.mooling-nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.codex-bin;
  launcher = name: directory:
    pkgs.writeShellScriptBin name ''
      export CODEX_HOME="/home/mirin/${directory}"
      exec ${codexBin}/bin/codex "$@"
    '';
  configSync = pkgs.writeShellScriptBin "codex-config-sync" ''
    exec ${pkgs.python3}/bin/python3 ${./codex-config-sync.py} "$@"
  '';
  verifyBusiness = pkgs.writeShellScriptBin "codex-business-verify" ''
    exec ${pkgs.python3}/bin/python3 ${./codex-profile-verify.py} "$@"
  '';
  agent = account: {
    Unit = {
      Description = "Codex usage telemetry (${account})";
      After = ["network-online.target"];
      Conflicts = lib.optional (account == "personal") "codex-usage-agent.service";
      # Business stays dormant until workspace identity is verified locally.
      ConditionPathExists = lib.optional (account == "business") "/home/mirin/.config/codex-usage-monitor/business/identity-verified";
    };
    Service = {
      ExecCondition = lib.optional (account == "business") "${verifyBusiness}/bin/codex-business-verify --check";
      Environment = "PYTHONPATH=/home/mirin/.local/share/codex-usage-monitor/src";
      ExecStart = "${pkgs.python3}/bin/python3 -m codex_usage_monitor agent --config /home/mirin/.config/codex-usage-monitor/${account}/agent.toml";
      Restart = "always";
      RestartSec = 5;
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = ["/home/mirin/.local/state/codex-usage-monitor/${account}"];
    };
    Install.WantedBy = ["default.target"];
  };
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
  home.activation.retireLegacyCodexAgent = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if ${pkgs.systemd}/bin/systemctl --user is-enabled --quiet codex-usage-agent.service; then
      run ${pkgs.systemd}/bin/systemctl --user disable --now codex-usage-agent.service
    fi
  '';
  systemd.user.services.codex-usage-personal = agent "personal";
  systemd.user.services.codex-usage-business = agent "business";
  # Keep MCP server commands declarative so their Nix store paths follow
  # package updates. Codex settings, authentication, and skills stay local.
  programs.mcp = {
    enable = true;
    servers.nixos.command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    servers.git.command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
  };

  home.packages = [
    codexGuiSudo
    codexBin
    (lib.hiPrio (launcher "codex" ".codex"))
    (launcher "codex-business" ".codex-business")
    configSync
    verifyBusiness
    pkgs.mcp-nixos
    pkgs.mcp-server-git
    pkgs.llm-agents.chatgpt
  ];
}
