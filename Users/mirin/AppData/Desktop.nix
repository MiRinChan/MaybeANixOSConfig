{pkgs, ...}: {
  home.packages = with pkgs; [
    catppuccin-kde
    klassy-qt6
    plasma-overdose-kde-theme
    whitesur-cursors
  ];
}
