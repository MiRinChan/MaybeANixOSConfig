{
  config,
  repoRoot,
  ...
}: {
  sops = {
    age.keyFile = "/home/mirin/.config/sops/age/keys.txt";
    defaultSopsFile = repoRoot + "/ProgramData/SOPS/mirin.yaml";
    secrets = {
      "fx/closedai-gemini-api-key" = {};
      "fx/closedai-claude-api-key" = {};
      "fx/closedai-grok-api-key" = {};
      "fx/closedai-chatgpt-api-key" = {};
      "fx/deepseek-api-key" = {};
    };
  };

  programs.zsh.initContent = ''
    if [[ -r "${config.sops.secrets."fx/closedai-gemini-api-key".path}" ]]; then
      export CLOSEDAI_GEMINI_API_KEY="$(<"${config.sops.secrets."fx/closedai-gemini-api-key".path}")"
    fi
    if [[ -r "${config.sops.secrets."fx/closedai-claude-api-key".path}" ]]; then
      export CLOSEDAI_CLAUDE_API_KEY="$(<"${config.sops.secrets."fx/closedai-claude-api-key".path}")"
    fi
    if [[ -r "${config.sops.secrets."fx/closedai-grok-api-key".path}" ]]; then
      export CLOSEDAI_GROK_API_KEY="$(<"${config.sops.secrets."fx/closedai-grok-api-key".path}")"
    fi
    if [[ -r "${config.sops.secrets."fx/closedai-chatgpt-api-key".path}" ]]; then
      export CLOSEDAI_CHATGPT_API_KEY="$(<"${config.sops.secrets."fx/closedai-chatgpt-api-key".path}")"
    fi
    if [[ -r "${config.sops.secrets."fx/deepseek-api-key".path}" ]]; then
      export DEEPSEEK_API_KEY="$(<"${config.sops.secrets."fx/deepseek-api-key".path}")"
    fi
  '';
}
