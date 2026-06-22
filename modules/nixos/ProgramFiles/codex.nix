{pkgs, ...}: let
  codexSettings = {
    features.memories = true;
    features.multi_agent = true;
    memories.disable_on_external_context = true;
    mcp_servers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      enabled = true;
    };
    mcp_servers.git = {
      command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
      enabled = true;
    };
  };
  codexSystemConfig = (pkgs.formats.toml {}).generate "codex-config" codexSettings;
in {
  environment.etc."codex/config.toml".source = codexSystemConfig;
}
