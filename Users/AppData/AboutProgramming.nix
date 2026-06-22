{
  config,
  lib,
  pkgs,
  ...
}: let
  condaWrapper = pkgs.writeShellScriptBin "conda" ''
    if [ "''${1-}" = "activate" ] || [ "''${1-}" = "deactivate" ]; then
      echo "conda $1 must be handled by the shell hook. Open a new zsh session and run it there." >&2
      exit 1
    fi

    if [ -x "$HOME/.conda/bin/conda" ]; then
      exec "$HOME/.conda/bin/conda" "$@"
    fi

    exec ${pkgs.conda}/bin/conda-shell -c 'conda "$@"' conda "$@"
  '';
in {
  programs.vscode = {
    enable = true;
    # package = pkgs.vscode.override {commandLineArgs = "--locale=zh-CN --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --enable-wayland-ime ";};
    package = pkgs.vscode.override {commandLineArgs = "--enable-wayland-ime -r";};
  };
  programs.direnv.enable = true;
  programs.zsh.initContent = lib.mkAfter ''
    if [ -x "$HOME/.conda/bin/conda" ]; then
      __conda_setup="$(CONDA_AUTO_ACTIVATE_BASE=false "$HOME/.conda/bin/conda" shell.zsh hook 2> /dev/null)"
    else
      __conda_setup="$(CONDA_AUTO_ACTIVATE_BASE=false ${pkgs.conda}/bin/conda-shell -c 'conda shell.zsh hook' 2> /dev/null)"
    fi

    if [ -n "$__conda_setup" ]; then
      eval "$__conda_setup"
    fi
    unset __conda_setup
  '';
  home.packages = with pkgs; [
    # 编程环境
    devbox
    direnv
    uv
    conda
    condaWrapper
    micromamba
    git-repo
    act
    ghidra
    devenv
    rkdeveloptool
  ];
}
