{
  config,
  inputs,
  pkgs,
  ...
}: let
  piPkg = config.programs.pi-coding-agent.package;

  # Catppuccin Mocha
  catppuccinMochaTheme = {
    name = "catppuccin-mocha";
    vars = {
      cyan = "#89dceb";
      blue = "#89b4fa";
      green = "#a6e3a1";
      red = "#f38ba8";
      yellow = "#f9e2af";
      text = "#cdd6f4";
      gray = "#a6adc8";
      dimGray = "#6c7086";
      darkGray = "#45475a";
      accent = "#b4befe";
      selectedBg = "#313244";
      userMsgBg = "#313244";
      toolPendingBg = "#2e2e3e";
      toolSuccessBg = "#2b3428";
      toolErrorBg = "#3a2830";
      customMsgBg = "#2d2838";
    };
    colors = {
      accent = "accent";
      border = "blue";
      borderAccent = "cyan";
      borderMuted = "darkGray";
      success = "green";
      error = "red";
      warning = "yellow";
      muted = "gray";
      dim = "dimGray";
      text = "text";
      thinkingText = "gray";
      selectedBg = "selectedBg";
      scrollbarThumb = "selectedBg";
      searchMatchBg = "selectedBg";
      searchMatchText = "text";
      userMessageBg = "userMsgBg";
      userMessageText = "text";
      customMessageBg = "customMsgBg";
      customMessageText = "text";
      customMessageLabel = "#cba6f7";
      toolPendingBg = "toolPendingBg";
      toolSuccessBg = "toolSuccessBg";
      toolErrorBg = "toolErrorBg";
      toolTitle = "text";
      toolOutput = "gray";
      mdHeading = "#f9e2af";
      mdLink = "#89b4fa";
      mdLinkUrl = "dimGray";
      mdCode = "accent";
      mdCodeBlock = "green";
      mdCodeBlockBorder = "gray";
      mdQuote = "gray";
      mdQuoteBorder = "gray";
      mdHr = "gray";
      mdListBullet = "accent";
      toolDiffAdded = "green";
      toolDiffRemoved = "red";
      toolDiffContext = "gray";
      syntaxComment = "#6c7086";
      syntaxKeyword = "#cba6f7";
      syntaxFunction = "#89b4fa";
      syntaxVariable = "#f9e2af";
      syntaxString = "#a6e3a1";
      syntaxNumber = "#fab387";
      syntaxType = "#89dceb";
      syntaxOperator = "#cdd6f4";
      syntaxPunctuation = "#cdd6f4";
      thinkingOff = "darkGray";
      thinkingMinimal = "#585b70";
      thinkingLow = "#74c7ec";
      thinkingMedium = "#89b4fa";
      thinkingHigh = "#cba6f7";
      thinkingXhigh = "#f5c2e7";
      thinkingMax = "#f38ba8";
      bashMode = "green";
    };
    export = {
      pageBg = "#181825";
      cardBg = "#1e1e2e";
      infoBg = "#313244";
    };
  };
in {
  programs.pi-coding-agent = {
    enable = true;
    package = inputs.pi-flake.packages.${pkgs.stdenv.hostPlatform.system}.pi-coding-agent;
    agentFiles.settings.value = {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      theme = "catppuccin-mocha";

      # 从 pi 的资源列表里排除不用的 skill
      ignoredSkills = ["microsoft-foundry"];

      extensions = [
        "${pkgs.pi-permission-system}/src/index.ts"
        "${pkgs.pi-subagents}/index.ts"
        "${pkgs.pi-preferred-thinking}/src/index.ts"
        "${pkgs.pi-rtk-optimizer}/index.ts"
        "${pkgs.pi-fff}/src/index.ts"
        "${pkgs.pi-observational-memory}/src/index.ts"
        "${pkgs.pi-context-usage}/src/index.ts"
        "${pkgs.pi-jingle}/jingle.ts"
        "${pkgs.pi-btw}/extensions/btw.ts"
        "${pkgs.rpiv-ask-user-question}/index.ts"
        "${pkgs.pi-workspace-history}/.pi/extensions/workspace-history.ts"
        "${pkgs.pi-mcp-adapter}/index.ts"
        "${pkgs.pi-permission-auto-review}/dist/index.js"
      ];

      # pi-preferred-thinking：按模型固定思考强度
      preferredThinking = {
        "opencode-go/deepseek-v4-pro" = "max";
        "opencode-go/glm-5.2" = "max";
        "opencode-go/kimi-k2.7-code" = "max";
        "opencode-go/qwen3.7-plus" = "medium";
        "opencode-go/deepseek-v4-flash" = "max";
        "opencode-go/grok-4.5" = "medium";
        "opencode-go/kimi-k3" = "max";
      };

      # pi-observational-memory：后台记忆 worker 用便宜的 deepseek-v4-flash，
      # ratio 模式让压缩阈值跟随大上下文窗口
      observational-memory = {
        model = {
          provider = "opencode-go";
          id = "deepseek-v4-flash";
          thinking = "max";
        };
        compactAfterTokensMode = "ratio";
        compactAfterTokensRatio = 0.5;
        showWorkerNotifications = false;
      };

      # pi-jingle：默认用自带 done.mp3；想要 Navi 提示音时把文件放到
      # ~/.pi/sounds/navi.mp3 并改这里的 path 即可
      sounds.agent_end = {
        path = "${pkgs.pi-jingle}/sounds/done.mp3";
        volume = 0.5;
      };

      # pi-workspace-history：保持默认 storageDir（~/.pi/agent/state/workspace-history），
      # 不要改到工作目录内，避免影子仓库膨胀
      workspaceHistory = { enabled = true; };
    };
  };

  # provider 配置
  sops.templates = {
    "pi-models.json" = {
      path = "/home/mirin/.pi/agent/models.json";
      mode = "0600";
      content = ''
        {
          "providers": {
            "kylenqaq-openai": {
              "baseUrl": "${config.sops.placeholder.pi-kylenqaq-base-url}",
              "api": "anthropic-messages",
              "apiKey": "!cat ${config.sops.secrets.pi-kylenqaq-openai-api-key.path}",
              "compat": { "supportsEagerToolInputStreaming": false },
              "models": [
                { "id": "gpt-5.6-luna", "name": "GPT-5.6 Luna", "reasoning": true, "input": ["text", "image"], "contextWindow": 1050000, "maxTokens": 128000 },
                { "id": "gpt-5.6-sol", "name": "GPT-5.6 Sol", "reasoning": true, "input": ["text", "image"], "contextWindow": 1050000, "maxTokens": 128000 },
                { "id": "gpt-5.6-terra", "name": "GPT-5.6 Terra", "reasoning": true, "input": ["text", "image"], "contextWindow": 1050000, "maxTokens": 128000 }
              ]
            },
            "kylenqaq-claude": {
              "baseUrl": "${config.sops.placeholder.pi-kylenqaq-base-url}",
              "api": "anthropic-messages",
              "apiKey": "!cat ${config.sops.secrets.pi-kylenqaq-claude-api-key.path}",
              "compat": { "supportsEagerToolInputStreaming": false },
              "models": [
                { "id": "claude-opus-5", "name": "Claude Opus 5", "reasoning": true, "input": ["text", "image"], "contextWindow": 1000000, "maxTokens": 128000 },
                { "id": "claude-fable-5", "name": "Claude Fable 5", "reasoning": true, "input": ["text", "image"], "contextWindow": 1000000, "maxTokens": 128000 }
              ]
            },
            "kylenqaq-grok": {
              "baseUrl": "${config.sops.placeholder.pi-kylenqaq-base-url}",
              "api": "anthropic-messages",
              "apiKey": "!cat ${config.sops.secrets.pi-kylenqaq-grok-api-key.path}",
              "compat": { "supportsEagerToolInputStreaming": false },
              "models": [
                { "id": "grok-4.5", "name": "Grok 4.5", "reasoning": true, "input": ["text", "image"], "contextWindow": 1000000, "maxTokens": 128000 }
              ]
            },
            "opencode-go": {
              "apiKey": "!cat ${config.sops.secrets.pi-opencode-go-api-key.path}"
            }
          }
        }
      '';
    };
    # ~/.pi/agent/auth.json 由 pi 管理
  };

  # Catppuccin Mocha
  home.file.".pi/agent/themes/catppuccin-mocha.json" = {
    text = builtins.toJSON catppuccinMochaTheme;
  };

  # pi-permission-system 策略：OS 沙盒(bwrap)之上的审批层，映射 codex 的
  # approval_policy + 信任级别。路径保护 + bash 模式 + 工作区边界门。
  # authorizerChain 启用 "auto-review"（pi-permission-auto-review）：
  # 模型按 Codex Guardian 策略评估，安全操作自动放行，潜在危险才问用户。
  home.file.".pi/agent/extensions/pi-permission-system/config.json" = {
    text = builtins.toJSON {
      authorizerChain = ["auto-review"];
      permission = {
        "*" = "allow";
        path = {
          "*" = "allow";
          "*.env" = "deny";
          "*.env.*" = "deny";
          "*.env.example" = "allow";
          "~/.ssh/*" = "deny";
          "~/.aws/*" = "deny";
        };
        bash = {
          "*" = "ask";
          "rm -rf *" = "deny";
          "sudo *" = "ask";
        };
        external_directory = "ask";
      };
    };
  };

  # auto-review 判官模型配置：OpenAI 官方 codex-auto-review 模型，
  # 依赖 /login openai-codex 的 ChatGPT 订阅（与 codex auto_review 一致）。
  home.file.".pi/agent/extensions/pi-permission-auto-review/config.json" = {
    text = builtins.toJSON {
      provider = "openai-codex";
      model = "codex-auto-review";
      reasoning = "low";
      timeoutMs = 90000;
      includeBaselinePolicy = true;
    };
  };

  # bwrap 沙盒包装  整个 pi 进程按 codex workspace-write 隔离
  # 全局只读 工作区 / pi 状态 / 声音与 ssh-agent 套接字可写
  home.packages = with pkgs; [
    rtk # pi-rtk-optimizer 命令重写
    pulseaudio # paplay，供 pi-jingle 发声
    bubblewrap # bwrap 沙盒
    (writeShellScriptBin "pi-sandbox" ''
      set -euo pipefail
      pi="${piPkg}/bin/pi"
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

      bwrap_args=(
        --ro-bind / /
        --bind "$PWD" "$PWD"
      )
      for d in "$HOME/.pi" "$HOME/.local/share/pi" "$HOME/.cache" "$runtime_dir"; do
        if [ -d "$d" ]; then
          bwrap_args+=(--bind "$d" "$d")
        fi
      done
      bwrap_args+=(
        --bind /dev/pts /dev/pts
        --bind /dev/tty /dev/tty
        --dev /dev
        --proc /proc
        --tmpfs /tmp
        --unshare-pid --unshare-ipc --unshare-uts
      )

      exec ${bubblewrap}/bin/bwrap "''${bwrap_args[@]}" "$pi" "$@"
    '')
  ];
}
