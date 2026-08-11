{pkgs, ...}: {
  home.packages = with pkgs; [
    catppuccin-kde
    plasma-overdose-kde-theme
    whitesur-cursors
  ];
}
