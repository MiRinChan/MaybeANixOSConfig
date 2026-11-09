# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  gallant-terminal-nerd = pkgs.callPackage ./gallant-terminal-nerd {};
  openai-sans = pkgs.callPackage ./openai-sans {};
  scrcpy3 = pkgs.callPackage ./scrcpy3.nix {};
  tsuyaku = pkgs.callPackage ./tsuyaku.nix {};
  dsh = pkgs.callPackage ./dsh.nix {};
}
