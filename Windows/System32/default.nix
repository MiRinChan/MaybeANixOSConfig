{repoRoot, ...}: {
  imports = [
    ./configuration.nix
    ./boot.nix
    ./networking.nix
    ./nix.nix
    ./desktop.nix
    ./services.nix
    ./secrets.nix
    ./accounts.nix
    ./authentication.nix
    ./audio.nix
    ./localization.nix
    ./hardware-configuration.nix
    (repoRoot + "/Program Files")
    (repoRoot + "/Windows/Fonts")
    (repoRoot + "/Windows/DRIVER/nvidia.nix")
  ];
}
