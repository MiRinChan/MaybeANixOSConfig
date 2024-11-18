# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  klassy = pkgs.callPackage ./klassy.nix {};
  microsoft-emoji = pkgs.callPackage ./SegoeUIEmoji.nix {};
  rquickshare-legacy = pkgs.callPackage ./RQuickShare.nix {};
  signon-plugin-oauth2 = pkgs.callPackage ./signon-plugin-oauth2.nix {};
}
