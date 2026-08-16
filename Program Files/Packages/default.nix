# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs:
(import ./pi {inherit pkgs;})
// {
  # example = pkgs.callPackage ./example { };
  lunar = pkgs.callPackage ./lunar.nix {};
  rquickshare-the-legacy = pkgs.callPackage ./RQuickShare.nix {};
  scrcpy3 = pkgs.callPackage ./scrcpy3.nix {};
  tsuyaku = pkgs.callPackage ./tsuyaku.nix {};
  klassy-qt6 = pkgs.callPackage ./klassy-qt6 {};
  iloader = pkgs.callPackage ./iloader.nix {};
  dsh = pkgs.callPackage ./dsh.nix {};
}
