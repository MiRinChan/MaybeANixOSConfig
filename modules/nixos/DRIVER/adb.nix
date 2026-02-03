{
  config,
  lib,
  pkgs,
  ...
}: {
  # provide adb
  programs.android-tools.enable = true;
}
