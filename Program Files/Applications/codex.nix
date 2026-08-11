{pkgs, ...}: let
  codexSystemConfig = (pkgs.formats.toml {}).generate "codex-system-config" {
    # Keep only Nix store paths here. Personal Codex settings and
    # authentication are managed in the user's local configuration.
    mcp_servers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      enabled = true;
    };
    mcp_servers.git = {
      command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
      enabled = true;
    };
  };
in {
  environment.etc."codex/config.toml".source = codexSystemConfig;
}
