{
  config,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;
    # package = pkgs.vscode.override {commandLineArgs = "--locale=zh-CN --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --enable-wayland-ime ";};
    package = pkgs.vscode.override {commandLineArgs = "--enable-wayland-ime -r";};
  };
  programs.direnv.enable = true;
  home.packages = with pkgs; [
    # 编程环境
    devbox
    direnv
    conda
    git-repo
    act
    ghidra
    devenv
    zulu
    # gemini-cli
  ];
}
