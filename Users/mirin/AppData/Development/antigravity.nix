{
  config,
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  staticMcpConfig = jsonFormat.generate "antigravity-mcp-config.json" {
    mcpServers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    };
  };
in {
  # Keep the mcp-nixos store path updated across rebuilds while leaving
  # ~/.gemini/config/mcp_config.json mutable for `agy mcp` and Antigravity UI.
  home.activation.antigravityMcpConfig = lib.hm.dag.entryAfter ["linkGeneration"] (
    lib.hm.generators.mkImpureConfigMerger {
      inherit pkgs;
      format = "json";
      empty = "{}";
      jqOperation = "({ mcpServers: { nixos: { disabled: false } } } * $dynamic * $static)";
      path = "${config.home.homeDirectory}/.gemini/config/mcp_config.json";
      staticSettings = staticMcpConfig;
    }
  );

  home.packages = [
    pkgs.mcp-nixos
  ];
}
