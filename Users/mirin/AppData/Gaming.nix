{
  config,
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    osu-lazer
    lunar # Minecraft
    prismlauncher # Minecraft
    inputs.b-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.dataFile."applications/b-launcher.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=B Launcher
    GenericName=Minecraft Launcher
    Exec=${config.home.profileDirectory}/bin/b-launcher
    Icon=${config.home.profileDirectory}/share/icons/hicolor/scalable/apps/b-launcher.svg
    Terminal=false
    Categories=Game;
    Keywords=Minecraft;b-launcher;MC;
  '';
}
