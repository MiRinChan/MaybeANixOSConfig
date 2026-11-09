# Host-specific glue shared by the system modules.
{inputs, ...}: {
  nixpkgs = {
    overlays = with inputs.self.overlays; [
      additions
      llm-agents
      modifications
      master-packages
      unstable-packages
      stable-packages
      d209-packages
    ];
    config.allowUnfree = true;
  };

  catppuccin = {
    flavor = "mocha";
    enable = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
