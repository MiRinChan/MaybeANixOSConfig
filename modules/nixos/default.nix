# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  theProgramInstallForAllUsers = import ./ProgramFiles;
  localizationSettings = import ./LocalizationSettings.nix;
  nvidiaDriver = import ./DRIVER/nvidia.nix;
  ADBDriver = import ./DRIVER/adb.nix;
  soundSettings = import ./SoundSettings.nix;
  FHSEnviroment = import ./FHSEnviroment.nix;
}
