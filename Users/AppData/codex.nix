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
  };
  codexDefaultConfig = (pkgs.formats.toml {}).generate "codex-config-default" codexSettings;
  codexHome = "${config.home.homeDirectory}/.codex";
in {
  programs.mcp = {
    enable = true;
    servers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
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
