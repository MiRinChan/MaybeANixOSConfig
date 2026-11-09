{
  programs.git = {
    enable = true;
    package = null;
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
        signingKey = "6CA74D44095DEBB5DA35444508A5B955EF921DC3";
      };
      commit = {
        gpgsign = true;
      };
    };
    signing.format = "openpgp";
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
}
