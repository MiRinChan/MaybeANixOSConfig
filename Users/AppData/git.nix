{config, ...}: {
  programs.git = {
    enable = true;
    userName = "MiRinChan";
    userEmail = "148533509+MiRinChan@users.noreply.github.com";
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
}
