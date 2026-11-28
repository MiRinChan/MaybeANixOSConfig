{pkgs, ...}: let
  # Pure theme/icon-theme extensions migrated from ~/.local/share/zed/extensions.
  # HTML support is built into Gram 3.5.2.
  githubTheme =
    pkgs.runCommand "gram-extension-github-theme-0.1.9" {
      src = pkgs.fetchFromGitHub {
        owner = "PyaeSoneAungRgn";
        repo = "github-zed-theme";
        rev = "e76635cac62edaa1c66070e46f8a393008f2869a";
        hash = "sha256-DR8Kponfei9B1x9dVZdeMN0h9SzcLSMCkXpFe56SywM=";
      };
    } ''
      mkdir -p $out/share/gram/extensions/github-theme
      cp $src/extension.toml $out/share/gram/extensions/github-theme/
      cp -r $src/themes $out/share/gram/extensions/github-theme/
    '';

  materialIconTheme =
    pkgs.runCommand "gram-extension-material-icon-theme-1.3.2" {
      src = pkgs.fetchFromGitHub {
        owner = "zed-extensions";
        repo = "material-icon-theme";
        tag = "v1.3.2";
        hash = "sha256-JmUoqaY7Udzy39s3/ruuneqLSE0btGrmUV28uTClkwc=";
      };
    } ''
      mkdir -p $out/share/gram/extensions/material-icon-theme
      cp $src/extension.toml $out/share/gram/extensions/material-icon-theme/
      cp -r $src/icon_themes $src/icons $out/share/gram/extensions/material-icon-theme/
    '';
in {
  programs.gram = {
    enable = true;
    # Keep ~/.config/gram/settings.jsonc unmanaged so settings remain editable in Gram UI.
    extensionPackages = [
      githubTheme
      materialIconTheme
    ];
  };
}
