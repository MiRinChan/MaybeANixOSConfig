# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: let
  openchamberPackages = pkgs.callPackage ./openchamber {};
in {
  openchamber = openchamberPackages.cli;
  openchamber-desktop = openchamberPackages.desktop;

  # example = pkgs.callPackage ./example { };
  lunar = pkgs.callPackage ./lunar.nix {};
  microsoft-emoji = pkgs.callPackage ./SegoeUIEmoji.nix {};
  rquickshare-the-legacy = pkgs.callPackage ./RQuickShare.nix {};
  scrcpy3 = pkgs.callPackage ./scrcpy3.nix {};
  wallpaper-engine-kde-plugin = pkgs.callPackage ./wallpaper-engine-kde-plugin {};
  klassy-qt6 = pkgs.callPackage ./klassy-qt6 {};
  iloader = pkgs.callPackage ./iloader.nix {};
}
