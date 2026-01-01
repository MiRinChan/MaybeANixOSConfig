{config, ...}: {
  programs.git = {
    enable = true;
    settings = {
      init = {
        defaultBranch = "master";
      };
      url = {
        "https://github.com/" = {
          insteadOf = [
            "gh:"
            "github:"
          ];
        };
      };
      user = {
        name = "MiRinChan";
        email = "148533509+MiRinChan@users.noreply.github.com";
        signingKey = "08A5B955EF921DC3";
      };
      commit = {
        gpgsign = true;
      };
    };
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
}
