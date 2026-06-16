{pkgs, ...}: let
  kdeBackup = ../../backups/kde/20260616-215726;
  localShare = kdeBackup + /local-share;
in {
  # Theme packages that are available from nixpkgs or this flake's overlay.
  home.packages = with pkgs; [
    catppuccin-kde
    klassy-qt6
    plasma-overdose-kde-theme
    wallpaper-engine-kde-plugin
    whitesur-cursors
  ];

  # Local/user-modified KDE assets preserved from the migration backup.
  # These are not confidently available as matching nixpkgs packages, so deploy
  # the backed-up copies verbatim into XDG data paths.
  xdg.dataFile = {
    "plasma/desktoptheme/Frosted".source = localShare + /plasma/desktoptheme/Frosted;
    "plasma/desktoptheme/Moe".source = localShare + /plasma/desktoptheme/Moe;
    "plasma/desktoptheme/Moe-Dark".source = localShare + /plasma/desktoptheme/Moe-Dark;
    "plasma/desktoptheme/Scratchy".source = localShare + /plasma/desktoptheme/Scratchy;
    "plasma/desktoptheme/Windows-Beuty".source = localShare + /plasma/desktoptheme/Windows-Beuty;
    "plasma/desktoptheme/Windows-Beuty-Dark".source = localShare + /plasma/desktoptheme/Windows-Beuty-Dark;
    "plasma/desktoptheme/Windows-Eleven".source = localShare + /plasma/desktoptheme/Windows-Eleven;
    "plasma/desktoptheme/Windows-Eleven-Dark".source = localShare + /plasma/desktoptheme/Windows-Eleven-Dark;

    "plasma/look-and-feel/Moe".source = localShare + /plasma/look-and-feel/Moe;
    "plasma/look-and-feel/Scratchy".source = localShare + /plasma/look-and-feel/Scratchy;
    "plasma/look-and-feel/windows-eleven".source = localShare + /plasma/look-and-feel/windows-eleven;
    "plasma/look-and-feel/windows-eleven-Dark".source = localShare + /plasma/look-and-feel/windows-eleven-Dark;
    "plasma/look-and-feel/windows.eleven.Dark.P6".source = localShare + /plasma/look-and-feel/windows.eleven.Dark.P6;

    "aurorae/themes/Moe".source = localShare + /aurorae/themes/Moe;
    "aurorae/themes/MoeDark".source = localShare + /aurorae/themes/MoeDark;
    "aurorae/themes/Scratchy".source = localShare + /aurorae/themes/Scratchy;
    "aurorae/themes/Windows-Eleven-Dark".source = localShare + /aurorae/themes/Windows-Eleven-Dark;
    "aurorae/themes/irixium".source = localShare + /aurorae/themes/irixium;

    "color-schemes/AbsoluteDark.colors".source = localShare + /color-schemes/AbsoluteDark.colors;
    "color-schemes/CatppuccinMochaFlamingo.colors".source = localShare + /color-schemes/CatppuccinMochaFlamingo.colors;
    "color-schemes/Moe.colors".source = localShare + /color-schemes/Moe.colors;
    "color-schemes/MoeDark.colors".source = localShare + /color-schemes/MoeDark.colors;
    "color-schemes/PlasmaOverdose.colors".source = localShare + /color-schemes/PlasmaOverdose.colors;
    "color-schemes/Scratchy.colors".source = localShare + /color-schemes/Scratchy.colors;

    "icons/Cobalt".source = localShare + /icons/Cobalt;
    "icons/Cobalt-dark".source = localShare + /icons/Cobalt-dark;
    "icons/Colloid".source = localShare + /icons/Colloid;
    "icons/Colloid-dark".source = localShare + /icons/Colloid-dark;
    "icons/Colloid-light".source = localShare + /icons/Colloid-light;
    "icons/Eleven".source = localShare + /icons/Eleven;
    "icons/Eleven-Dark".source = localShare + /icons/Eleven-Dark;
    "icons/Eleven-Light".source = localShare + /icons/Eleven-Light;
    "icons/Irixium".source = localShare + /icons/Irixium;
    "icons/Windows-Beuty".source = localShare + /icons/Windows-Beuty;
    "icons/Windows-Eleven".source = localShare + /icons/Windows-Eleven;
    "icons/klassy".source = localShare + /icons/klassy;
    "icons/klassy-dark".source = localShare + /icons/klassy-dark;

    "wallpapers/Frozen.berries".source = localShare + /wallpapers/Frozen.berries;
    "wallpapers/Moe-DarkSouls".source = localShare + /wallpapers/Moe-DarkSouls;
    "wallpapers/Scratchy".source = localShare + /wallpapers/Scratchy;
    "wallpapers/Scratchy-V2".source = localShare + /wallpapers/Scratchy-V2;
    "wallpapers/Windows-Eleven-02".source = localShare + /wallpapers/Windows-Eleven-02;
    "wallpapers/moe.png".source = localShare + /wallpapers/moe.png;
    "wallpapers/purslane.Nord".source = localShare + /wallpapers/purslane.Nord;

    "fonts/JetBrainsMono-Bold.ttf".source = localShare + /fonts/JetBrainsMono-Bold.ttf;
    "fonts/NotoColorEmoji.ttf".source = localShare + /fonts/NotoColorEmoji.ttf;
    "fonts/SourceHanSans.ttc".source = localShare + /fonts/SourceHanSans.ttc;
  };
}
