{
  # 图形化
  services = {
    xserver.enable = true;
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  # Make electron and Chrome happy.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  programs.dconf.enable = true;
  xdg.portal.enable = true;
}
