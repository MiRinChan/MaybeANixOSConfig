# Host-specific glue shared by the system modules.
{
  inputs,
  repoRoot,
  ...
}: let
  programFiles = repoRoot + "/Program Files";
  overlays = import (programFiles + "/Overlays") {inherit inputs repoRoot;};
in {
  nixpkgs = {
    overlays = [
      overlays.additions
      overlays.llm-agents
      overlays.modifications
      overlays.master-packages
      overlays.unstable-packages
      overlays.stable-packages
      overlays.d209-packages
    ];
    config.allowUnfree = true;
  };

  catppuccin.flavor = "mocha";
  catppuccin.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
