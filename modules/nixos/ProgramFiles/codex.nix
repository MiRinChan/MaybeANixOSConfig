{pkgs, ...}: let
  deepseekResponsesProxy = pkgs.writeShellApplication {
    name = "codex-deepseek-responses-proxy";
    runtimeInputs = [pkgs.python3];
    text = ''
      exec python3 ${./codex-deepseek-responses-proxy.py} "$@"
    '';
  };
  codexSettings = {
    features.memories = true;
    features.multi_agent = true;
    features.multi_agent_v2 = true;
    features.child_agents_md = true;
    memories.disable_on_external_context = true;
    mcp_servers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      enabled = true;
    };
    mcp_servers.git = {
      command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
      enabled = true;
    };
    model_providers.deepseek = {
      name = "DeepSeek via local Responses proxy";
      base_url = "http://127.0.0.1:18888";
      experimental_bearer_token = "local-proxy";
      supports_websockets = false;
      stream_idle_timeout_ms = 600000;
      wire_api = "responses";
    };
  };
  codexSystemConfig = (pkgs.formats.toml {}).generate "codex-config" codexSettings;
in {
  environment.etc."codex/config.toml".source = codexSystemConfig;
  environment.systemPackages = [deepseekResponsesProxy];

  systemd.services.codex-deepseek-responses-proxy = {
    description = "Local Responses API proxy for Codex DeepSeek subagents";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    environment = {
      HOST = "127.0.0.1";
      PORT = "18888";
      DEEPSEEK_BASE_URL = "https://api.deepseek.com";
      DEEPSEEK_MODEL = "deepseek-v4-flash";
      DEEPSEEK_THINKING = "disabled";
    };
    serviceConfig = {
      ExecStart = "${deepseekResponsesProxy}/bin/codex-deepseek-responses-proxy";
      EnvironmentFile = "-/home/mirin/.config/codex/deepseek-proxy.env";
      Restart = "on-failure";
      RestartSec = "5s";
      DynamicUser = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
    };
  };
}
