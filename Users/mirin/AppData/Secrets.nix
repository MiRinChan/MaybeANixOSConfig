{repoRoot, ...}: {
  sops = {
    age.keyFile = "/home/mirin/.config/sops/age/keys.txt";
    defaultSopsFile = repoRoot + "/ProgramData/SOPS/mirin.yaml";
    secrets."pi-kylenqaq-openai-api-key" = {
      key = "pi/kylenqaq-openai-api-key";
    };
    secrets."pi-kylenqaq-claude-api-key" = {
      key = "pi/kylenqaq-claude-api-key";
    };
    secrets."pi-kylenqaq-grok-api-key" = {
      key = "pi/kylenqaq-grok-api-key";
    };
    secrets."pi-opencode-go-api-key" = {
      key = "pi/opencode-go-api-key";
    };
    secrets."pi-agentrouter-api-key" = {
      key = "pi/agentrouter-api-key";
    };
    secrets."pi-agentrouter-base-url" = {
      key = "pi/agentrouter-base-url";
    };
    secrets."pi-kylenqaq-base-url" = {
      key = "pi/kylenqaq-base-url";
    };
    secrets."pi-opencode-go-base-url" = {
      key = "pi/opencode-go-base-url";
    };
  };
}
