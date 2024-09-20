{
  config,
  lib,
  pkgs,
  ...
}: {
  # provide adb
  programs.adb.enable = true;
}
