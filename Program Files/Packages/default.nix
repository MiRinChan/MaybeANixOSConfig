# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  lunar = pkgs.callPackage ./lunar.nix {};
  rquickshare-the-legacy = pkgs.callPackage ./RQuickShare.nix {};
  scrcpy3 = pkgs.callPackage ./scrcpy3.nix {};
  klassy-qt6 = pkgs.callPackage ./klassy-qt6 {};
  iloader = pkgs.callPackage ./iloader.nix {};
}
