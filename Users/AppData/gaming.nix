{pkgs, ...}: {
  home.packages = with pkgs; [
    osu-lazer
    lunar # Minecraft
    prismlauncher # Minecraft
  ];
}
