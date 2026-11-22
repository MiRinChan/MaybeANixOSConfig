{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  codexDesktop = inputs.self.homeConfigurations.mirin.config.programs.codexDesktopLinux.package;
in {
  # The desktop package carries the Codex Micro udev policy. Publish it to
  # udev and expose its workspace runtime libraries to nix-ld so cached generic
  # Node/Python/pnpm runtimes remain usable inside the Codex command sandbox.
  services.udev.packages = [codexDesktop];
  programs.nix-ld.libraries = lib.mkIf config.programs.nix-ld.enable (
    codexDesktop.passthru.workspaceRuntimeLibraries or []
  );

  environment.etc."codex/config.toml".source = (pkgs.formats.toml {}).generate "codex-system-config" {
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
}
