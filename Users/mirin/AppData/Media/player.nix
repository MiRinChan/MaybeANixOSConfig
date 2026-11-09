{pkgs, ...}:
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
      package = pkgs.symlinkJoin {
        name = "obs-studio-${pkgs.obs-studio.version}-gpu";
        paths = [pkgs.obs-studio];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/obs \
            --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
        '';
        inherit (pkgs.obs-studio) meta passthru;
      };
    };
  };

  services = {
    playerctld.enable = true;
    easyeffects.enable = true;
  };
}
