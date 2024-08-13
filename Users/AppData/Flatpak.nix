{flake-inputs, ...}: {
  imports = [
    flake-inputs.flatpak.homeManagerModules.nix-flatpak
  ];
  # Flatpak
  services.flatpak.packages = [
    "com.tencent.WeChat"
    "com.obsproject.Studio"
    "io.github.kukuruzka165.materialgram"
    "com.jeffser.Alpaca"
    "com.github.neithern.g4music"
    {
      appId = "com.qq.QQ";
      origin = "qq-origin";
    }
    "com.wps.Office"
  ];

  services.flatpak.remotes = [
    {
      name = "qq-origin";
      location = "file:///home/mirin/FlatpakBuilds/com.qq.QQ-master/.flatpak-builder/cache";
      args = "--user --no-gpg-verify --prio=0 --no-enumerate --title=QQ";
    }
  ];
}
