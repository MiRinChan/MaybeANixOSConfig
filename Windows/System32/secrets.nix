{
  config,
  repoRoot,
  ...
}: {
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = repoRoot + "/ProgramData/SOPS/system.yaml";
    secrets.codex-deepseek-proxy-env = {
      format = "yaml";
      key = "codex_deepseek_proxy_env";
      restartUnits = ["codex-deepseek-responses-proxy.service"];
    };
  };

  systemd.services.codex-deepseek-responses-proxy.serviceConfig.EnvironmentFile =
    config.sops.secrets.codex-deepseek-proxy-env.path;
}
