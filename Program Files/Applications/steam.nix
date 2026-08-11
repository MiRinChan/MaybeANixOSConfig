{
  pkgs,
  config,
  ...
}: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    package = pkgs.steam;
    gamescopeSession = {
      enable = true;
    };
  };
  programs.gamescope = {
    enable = true;
    package = pkgs.gamescope;
  };
  environment.systemPackages = with pkgs; [
    protontricks
  ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
    package = pkgs.sunshine.overrideAttrs (old: {
      buildInputs =
        (old.buildInputs or [])
        ++ [
          pkgs.cudaPackages.cuda_cudart
          pkgs.cudaPackages.cuda_nvrtc
        ];

      postFixup =
        (old.postFixup or "")
        + ''
          wrapProgram $out/bin/sunshine \
            --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib:${pkgs.cudaPackages.cuda_cudart}/lib:${pkgs.cudaPackages.cuda_nvrtc}/lib
        '';
    });
  };
  hardware.uinput.enable = true;
}
