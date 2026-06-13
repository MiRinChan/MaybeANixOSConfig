{
  pkgs,
  config,
  ...
}:
# media - control and enjoy audio/video
{
  # imports = [
  # ];

  home.packages = with pkgs; [
    # audio control
    pavucontrol
    playerctl
    pulsemixer
    # images
    imv
  ];

  programs = {
    mpv = {
      enable = true;
      defaultProfiles = ["gpu-hq"];
      scripts = [pkgs.mpvScripts.mpris];
    };

    obs-studio = {
      enable = true;
      package = pkgs.obs-studio.overrideAttrs (old: {
        postFixup =
          (old.postFixup or "")
          + ''
            wrapProgram $out/bin/obs \
              --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
          '';
      });
    };
  };

  services = {
    playerctld.enable = true;
    easyeffects.enable = true;
  };
}
