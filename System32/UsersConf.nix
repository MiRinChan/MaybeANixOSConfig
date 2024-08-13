{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  users.users = {
    mirin = {
      # 别忘了设密码
      isNormalUser = true;
      extraGroups = ["wheel" "adbusers"];
      shell = pkgs.zsh;
    };
  };

  environment.sessionVariables = {
    STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
  };
}
