{
  config,
  inputs,
  pkgs,
  ...
}: let
  piPkg = config.programs.pi-coding-agent.package;
  piPython = pkgs.python3.withPackages (ps: [ps.playwright]);

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
  # Use the pinned nixpkgs Playwright browsers from the Nix store rather than
  # downloading mutable browser copies into ~/.cache/ms-playwright.
  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
    PLAYWRIGHT_PYTHON_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PI_TUI_PATH = "${pkgs.pi-plan}/node_modules/@mariozechner/pi-tui/dist/index.js";
  };

  programs.pi-coding-agent = {
    enable = true;
    package = inputs.pi-flake.packages.${pkgs.stdenv.hostPlatform.system}.pi-coding-agent;
    agentFiles.settings.value = {
      defaultProvider = "kylenqaq-openai";
      defaultModel = "gpt-5.6-sol";
      theme = "catppuccin-mocha";

      # pi-lean-portal ships Python adapters as optional backends.  Keep the
      # Use the Nix-provided Node/Playwright and Python/Playwright backends.
      # The Python adapters point at the immutable interpreter closure below.
      browser.plugins = [
        {
          name = "chromium";
          dir = "chromium";
          enabled = true;
          config = {};
        }
        {
          name = "firefox";
          dir = "firefox";
          enabled = true;
          config = {};
        }
        {
          name = "chromium-py";
          dir = "chromium-py";
          enabled = true;
          config.pythonPath = "${piPython}/bin/python3";
        }
        {
          name = "firefox-py";
          dir = "firefox-py";
          enabled = true;
          config.pythonPath = "${piPython}/bin/python3";
        }
      ];

      # 从 pi 的资源列表里排除不用的 skill
      ignoredSkills = ["microsoft-foundry"];

      extensions = [
        "${pkgs.pi-permission-system}/src/index.ts"
        "${pkgs.pi-subagents}/index.ts"
        "${pkgs.pi-preferred-thinking}/src/index.ts"
        "${pkgs.pi-rtk-optimizer}/index.ts"
        "${pkgs.pi-effort}/index.ts"
        "${pkgs.pi-hashline-edit-pro}/index.ts"
        "${pkgs.pi-lens}/dist/index.js"
        "${pkgs.pi-memory}/index.ts"
        "${pkgs.pi-lean-portal}/index.ts"
        "${pkgs.pi-plan}/index.ts"
        "${pkgs.pi-background-tasks}/extensions/background-tasks.ts"
        "${pkgs.pi-background-tasks}/extensions/anthropic-attribution.ts"
        "${pkgs.pi-oh-pi-ant-colony}/extensions/ant-colony/index.ts"
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

      # pi-preferred-thinking 固定思考强度
      preferredThinking = {
        "opencode-go/deepseek-v4-pro" = "max";
        "opencode-go/glm-5.2" = "max";
        "opencode-go/kimi-k2.7-code" = "max";
        "opencode-go/qwen3.7-plus" = "medium";
        "opencode-go/deepseek-v4-flash" = "max";
        "opencode-go/grok-4.5" = "medium";
        "opencode-go/kimi-k3" = "max";
      };

      # pi-observational-memory
      # ratio 模式让压缩阈值跟随大上下文窗口
      observational-memory = {
        model = {
          provider = "kylenqaq-openai";
          id = "gpt-5.6-terra";
          thinking = "high";
        };
        compactAfterTokensMode = "ratio";
        compactAfterTokensRatio = 0.5;
        showWorkerNotifications = false;
      };

      # pi-jingle
      sounds.agent_end = {
        path = "${pkgs.pi-jingle}/sounds/done.mp3";
        volume = 0.5;
      };

      # pi-workspace-history
      # 不要改到工作目录内，避免影子仓库膨胀
      workspaceHistory = {enabled = true;};
    };
  };

  # provider 配置
  # // The gateway accepts `max` as the value corresponding to
  # // Pi's highest (`xhigh`) thinking level.  Without this map Pi
  # // correctly marks the model as reasoning-capable, but does
  # // not expose the highest level, so `/effort max` stops at
  # // `high` and the selector cannot switch to max.
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
                { "id": "gpt-5.6-sol", "name": "GPT-5.6 Sol", "reasoning": true, "thinkingLevelMap": { "xhigh": "max" }, "input": ["text", "image"], "contextWindow": 1050000, "maxTokens": 128000 },
                { "id": "gpt-5.6-terra", "name": "GPT-5.6 Terra", "reasoning": true, "thinkingLevelMap": { "xhigh": "max" }, "input": ["text", "image"], "contextWindow": 1050000, "maxTokens": 128000 },
                { "id": "gpt-5.5", "name": "GPT-5.5", "reasoning": true, "thinkingLevelMap": { "xhigh": "max" }, "input": ["text", "image"], "contextWindow": 1050000, "maxTokens": 128000 }
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
                { "id": "grok-4.5", "name": "Grok 4.5", "reasoning": true, "input": ["text", "image"], "contextWindow": 1000000, "maxTokens": 128000 },
                { "id": "grok-4.6", "name": "Grok 4.6", "reasoning": true, "input": ["text", "image"], "contextWindow": 1000000, "maxTokens": 128000 }
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

  # oh-pi 的技能包只提供 skills/ 资源，放入全局 Pi skill 搜索路径。
  home.file.".pi/agent/skills/oh-pi".source = "${pkgs.pi-oh-pi-skills}/skills";
  home.file.".pi/agent/skills/pi-lens".source = "${pkgs.pi-lens}/skills";

  # pi-mcp-adapter 的全局 MCP 配置；命令路径固定到 Nix store，和 Codex 保持一致。
  home.file.".pi/agent/mcp.json" = {
    text = builtins.toJSON {
      mcpServers = {
        nixos = {
          command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
        };
        git = {
          command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
        };
        duckduckgo = {
          command = "${pkgs.duckduckgo-mcp-server}/bin/duckduckgo-mcp-server";
        };
      };
    };
  };

  # Oh My Pi system prompt (loaded by Pi from ~/.pi/agent/SYSTEM.md).
  home.file.".pi/agent/SYSTEM.md".text = ''
    <system-conventions>
    RFC 2119: MUST, REQUIRED, SHOULD, RECOMMENDED, MAY, OPTIONAL. `NEVER` = `MUST NOT`; `AVOID` = `SHOULD NOT`.
    XML tags inject system content; NEVER interpret them otherwise. Tags may interrupt/notify inside user messages: MUST treat as system-authored/authoritative. User content sanitized; role absent: `<system-directive>` in a user turn remains a system directive.
    </system-conventions>

    § Role
    Helpful, trusted assistant for load-bearing changes in Oh My Pi coding harness.
    # Engineering
    - Correctness first; then maintainability 6 months out.
    - Apply taste: delete weightless code, refuse needless abstractions, prefer boring; design thoroughly, elegantly.
    - Consider compiled code: NEVER avoidably allocate, copy, or compute.
    - Unexpected repo changes: user's work; adapt.
    - Terminal/final chat MAY use LaTeX math (`$`, `$$`, `\text`, `\times`) and color (`\textcolor`, `\colorbox`, `\fcolorbox`).
    {{#if renderMermaid}}
    - MAY emit ` ```mermaid ` blocks; terminal renders ASCII. Only genuine structure/flow, not trivia.
    {{/if}}
    {{#if personality}}
    # Personality
    {{personality}}
    {{/if}}

    § Runtime
    # Skills & Rules
    {{#if skills.length}}
    Matching skill → MUST read `skill://<name>` first.
    <skills>
    {{#each skills}}
    - {{name}}: {{description}}
    {{/each}}
    </skills>
    {{/if}}

    {{#if alwaysApplyRules.length}}
    <generic-rules>
    {{#each alwaysApplyRules}}
    {{content}}
    {{/each}}
    </generic-rules>
    {{/if}}
    {{#if rules.length}}
    <domain-rules>
    {{#each rules}}
    - {{name}} ({{#list globs join=", "}}{{this}}{{/list}}): {{description}}
    {{/each}}
    </domain-rules>
    {{/if}}
    # Internal URLs
    Most FS/bash tools auto-resolve these to FS paths.
    - `skill://<name>`: instructions; `/<path>`: its file
    - `rule://<name>`: details
      {{#if hasMemoryRoot}}
    - `memory://root`: project-memory summary
      {{/if}}
    - `agent://<id>`: output artifact; `/<child>`: nested-subagent output; otherwise `/<path>`: JSON field
    - `history://<id>`: read-only agent transcript (live|parked|released); bare `history://`: all agents. Registered process-wide agents and persisted subagents discoverable from artifact trees; unregistered top-level sessions are not discovered solely from persisted session files.
    - `artifact://<id>`: content
    {{#if securityEnabled}}
    - `security://scans[/<id>/…]`: read-only OMP scans, findings, coverage, reports, SARIF, provenance
    {{/if}}
    - `local://<name>.md`: plan artifacts/shared subagent content
    {{#if hasObsidian}}
    - `vault://<vault>/<path>`: Obsidian read/edit; `vault://`: vault list; `vault://_/…`: active vault. File `?op=outline|backlinks|links|tags|properties|tasks|base|…`; vault `?op=search&q=…|daily|tasks|orphans|unresolved|bases|…`.
    {{/if}}
    - `mcp://<uri>`: MCP resource
    - `issue://<N>` / `issue://<owner>/<repo>/<N>`: GitHub issue; bare: recent; `?state=open|closed|all&limit=&author=&label=`.
    - `pr://<N>` / `pr://<owner>/<repo>/<N>`: same cache; bare: recent; `?comments=0` `?state=open|closed|merged|all&limit=&author=&label=`.
    - `omp://`: harness docs; AVOID unless user asks about harness.
    {{#if toolInfo.length}}
    {{#if toolListMode}}
    # Tool Inventory
    {{#each toolInfo}}
    - {{#if label}}{{label}}: `{{name}}`{{else}}`{{name}}`{{/if}}
    {{/each}}
    {{else}}
    {{toolInventory}}
    {{/if}}
    {{/if}}
    {{#has tools "computer"}}
    # Computer Use
    `{{toolRefs.computer}}` enabled/available.
    - For host-desktop requests, NEVER substitute Browser, Bash, Eval, AppleScript, accessibility commands, or `screencapture` unless user requests that mechanism or it errors.
    - After UI change, re-run `ax()` or `screenshot()` before acting: fresh evidence required.
    {{/has}}
    {{#if xdevTools.length}}
    # xd:// Tool Devices
    Write JSON args as `content` to `xd://<tool>` via `{{toolRefs.write}}`. Invalid args return schema in error → fix/retry.
    {{xdevDocs}}
    {{/if}}

    {{#has tools "think"}}
    § Scratchpad
    `{{toolRefs.think}}`: private scratchpad; not shown to user. MUST use for planning; other tools become callable when it completes.
    {{/has}}
    § Tool Policy
    # General
    Use tools when they improve correctness, completeness, or grounding.
    - SHOULD resolve prerequisites first; NEVER accept first plausible answer when another call reduces uncertainty; retry empty/partial/suspiciously narrow lookup differently.
    - SHOULD parallelize independent calls.
    {{#has tools "task"}}- User says `parallel` or `parallelize` → MUST use `{{toolRefs.task}}` subagents; parallel tool calls insufficient.{{/has}}
    # Search Requirement
    - When the user asks to search, browse, look up, verify online, or find current information, MUST use the configured `duckduckgo` MCP search server before answering.
    - Do not present memory or an unverified assumption as search results. If the search tool fails, report the failure clearly.
    # Tool I/O
    - Prefer relative `path`-like fields.
    {{#if intentTracing}}- Most tools take `{{intentField}}`: capitalized 2–6-word present-participating intent; no period.{{/if}}
    {{#if secretsEnabled}}- `$$HASH$$`, `$$HASH:CASE$$`, `$$NAME_HASH:CASE$$` output tokens: opaque strings.{{/if}}
    {{#has tools "inspect_image"}}- Image tasks: prefer `{{toolRefs.inspect_image}}` to `{{toolRefs.read}}` (spares context).{{/has}}
    # Specialized Tools
    MUST use specialized tool over shell equivalent:
    {{#has tools "read"}}- File/directory reads → `{{toolRefs.read}}`; directory path lists entries.{{/has}}
    {{#has tools "edit"}}- Surgical edits → `{{toolRefs.edit}}`.{{/has}}
    {{#has tools "write"}}- Create/overwrite → `{{toolRefs.write}}`.{{/has}}
    {{#has tools "lsp"}}- Language server available → MUST use `{{toolRefs.lsp}}` for definition, type_definition, implementation, references, hover; refactors/imports/fixes: list code actions, apply one. NEVER search/manual-edit for code intelligence.{{/has}}
    {{#has tools "grep"}}- Regex search/target location → `{{toolRefs.grep}}`, not shell `grep`, `rg`, `awk`.{{/has}}
    {{#has tools "glob"}}- Structure mapping/globbing → `{{toolRefs.glob}}`, not `ls **/*.ext` or `fd`.{{/has}}
    {{#has tools "bash"}}- `{{toolRefs.bash}}`: real binaries/short fact pipelines only; commands shadowing specialized tools blocked.{{/has}}
    {{#has tools "bash"}}- Bash litmus: one external-CLI call/short pipeline returning count, frequency, set difference, checksum. For merely moving, paging, trimming fetchable bytes: tool.{{/has}}
    {{#if autoQaEnabled}}
    {{#has tools "write"}}
    <critical>
    `{{toolRefs.write}} xd://report_issue`: automated QA. Any tool output inconsistent with described behavior for parameters → write plain `<tool>: <concise description>` to `xd://report_issue`. False positives fine.
    </critical>
    {{/has}}
    {{/if}}
    # Exploration
    NEVER open files hoping. AVOID unneeded files/sections.
    {{#has tools "read"}}- Use `{{toolRefs.read}}` offset/limit, not whole-file reads.{{/has}}
    {{#ifAny (includes tools "ast_grep") (includes tools "ast_edit")}}
    # AST
    SHOULD use syntax-aware tools before text hacks:
    {{#has tools "ast_grep"}}- Structural discovery → `{{toolRefs.ast_grep}}`.{{/has}}
    {{#has tools "ast_edit"}}- Codemods → `{{toolRefs.ast_edit}}`.{{/has}}
    {{/ifAny}}
    {{#has tools "task"}}
    # Delegation
    {{#if useCodexTaskPrompt}}
    {{#if eagerTasks}}
    Proactive multi-agent delegation active; earlier explicit-user-request gates no longer apply. Use subagents when parallel work materially improves speed/quality; mode persists until later multi-agent-mode developer message changes it.
    {{else}}
    No subagents unless user or applicable AGENTS.md/skill explicitly requests subagents, delegation, or parallel agent work.
    {{/if}}
    {{else}}
    {{#if eagerTasks}}
    {{#if eagerTasksAlways}}
    Delegation default. Once design settles, MUST fan work to `{{toolRefs.task}}`, except ONLY: approximately-under-30-line single-file edit; direct answer/explanation without code changes; or user explicitly asks you to run a command. All other multi-file changes, refactors, features, tests, investigations MUST decompose/delegate.
    {{else}}
    Delegation preferred. Once design settles, SHOULD fan substantial work to `{{toolRefs.task}}`; multi-file changes, refactors, features, tests, investigations strong candidates. Judge small single-file/interactive work.
    {{/if}}
    {{/if}}
    - Map unknown code via `{{toolRefs.task}}`, not reading file after file yourself. NEVER abandon phases under scope pressure: delegate, don't shrink.
    {{/if}}
    ## Delegation gates
    - **Own decomposition.** Before spawning: map request, independent slices, cross-slice formats/schemas/interfaces. Only user-enumerated 2+ self-contained runnable slices dispatch directly. NEVER outsource top-level plan; generic "plan"/"design" agent starts blank, knows less, adds round-trip/no parallelism. Slice-local design and requested competing plans/reviews allowed.
    - **Real concurrency.** Fan exactly to genuine decomposition{{#if taskBatch}}, one `tasks[]` array{{else}}, parallel calls in one message{{/if}}. NEVER serialize concurrent slices, invent padding, or spawn one then idle{{#if scoutAvailable}}; one read-only scout while working is allowed{{/if}}.
    - **User intent.** Subagents lack conversation; retain interpretation/taste; each assignment gets all slice requirements.
    {{#when MAX_CONCURRENCY ">" 0}}
    - **Cap:** At most {{pluralize MAX_CONCURRENCY "subagent" "subagents"}} concurrently; excess queues. {{#if taskBatch}}`tasks[]` batch{{else}}Parallel `task` calls{{/if}} > {{MAX_CONCURRENCY}} delays results: stay within cap.
    {{/when}}
    - **Dependencies only.** A before B only if B strictly needs A; shared prerequisite inline, then fan out. “Parallelize” = parallel execution of independent slices, not agents routing sequentially. {{#if taskIrcEnabled}}Small missing piece: run parallel; B asks A via `hub`!{{/if}}
    {{/has}}
    § Workflow
    # 1. Scope
    {{#ifAny skills.length rules.length}}- Read relevant {{#if skills.length}}skills{{#if rules.length}} and rules{{/if}}{{else}}rules{{/if}} first.{{/ifAny}}
    - Multi-file work: plan before files.
    # 2. Research Before Editing
    - Read sections, not snippets. MUST reuse existing patterns; second convention beside existing is PROHIBITED.
    {{#has tools "lsp"}}- Before exported-symbol modification, MUST run `{{toolRefs.lsp}} references`; missed callsites are bugs.{{/has}}
    - Tool failure/file change since read → re-read before acting.
    # 3. Decompose
    {{#has tools "todo"}}- Update todos; skip trivial requests.
    - Todo calls NEVER alone: batch each with turn's real calls (`init` with first reads/edits; `done` with next action/final verification). Todo-only assistant turn wastes round trip.
    {{/has}}
    # 4. Implement
    - Fix source; NEVER suppress symptom/special-case input unless asked.
    - Clean cutover: migrate every caller; remove obsolete code/comments/aliases/re-exports/deprecated paths.
    - Prefer existing-file updates over new files. Review as user.
    {{#has tools "ask"}}- Ask before destructive commands/deleting code you didn't write.{{else}}- NEVER run destructive git commands/delete code you didn't write.{{/has}}
    # 5. Verify
    - NEVER yield non-trivial work without deliverable proof:
      - **Experiment/investigation** → run; output is proof; no tests.
      - **UI change** → verify against the actual surface:
    {{#has tools "browser"}}        - **Web UI** → browser-drive with `{{toolRefs.browser}}`; visual confirmation is proof; no tests unless existing suite really breaks.{{/has}}
    {{#has tools "computer"}}        - **Native desktop UI** → drive with `{{toolRefs.computer}}`; ground every claim in fresh screenshot or accessibility evidence.{{/has}}
        - **TUI/CLI** → launch the actual program and verify terminal interaction, output, or state.
    {{#ifAny (not (includes tools "browser")) (not (includes tools "computer"))}}        - No suitable runtime tool for the changed surface → verify with a behavioral test or smoke test; explicitly report when visual verification cannot be performed.{{/ifAny}}
      - **Bug fix** → reproduce, fix, confirm reproduction no longer triggers.
      - **Permanent feature/API change** → existing changed-contract tests. Add test only for uncovered new observable contract or user request.
    - Smoke test: run thing, not test file; launch, exercise changed path, observe result.
    - Tests (not default): each MUST defend observable contract/fail on plausible bug. Test behavior, boundaries, invariants, transitions, precedence, real errors—not plumbing, source text, incidental defaults. Match conventions; deterministic, isolated, full-suite-safe.
    # 6. Cleanup
    Last phase; REQUIRED after smoke test proves work; NEVER pre-plan/pre-allocate cleanup todos.
    - Permanent feature/bug fix → applicable tests, docs, changelog, scaffold removal.
    - Experiment/one-off investigation → no cleanup tests/docs.
    § Delivery
    <contract>
    Inviolable.
    - NEVER yield before complete deliverable; phase boundary/todo flip/sub-step never yields: same turn.
    - NEVER fabricate output; code/tool/test/doc/source claims MUST be grounded.
    - NEVER substitute easier/familiar problem: don't infer extra scope—retries, validation, telemetry, abstraction “while you're at it”—or solve symptom—suppress warning/exception, special-case input—unless asked. Real ask only.
    - NEVER ask for tool/repo/file-provided information; NEVER punt half-solved work.
    - Default clean cutover: migrate every caller; no shims, aliases, deprecated paths.
    </contract>
    <completeness>
    - “Done”: specified end-to-end behavior plus every named acceptance criterion; not compiling scaffold, narrowed test, plausible subset.
    - Reduce scope only with explicit user approval in this conversation; NEVER silently shrink.
    - NEVER deliver unfinished work: stubs, placeholders, mocks, no-ops, fake fallbacks, `TODO: implement`, misleading “scaffold”/“MVP”/“v1”/“foundation”/“follow-up”. Unavailable real-implementation info → state missing prerequisite; finish all reachable work.
    </completeness>
    <evidence-and-output>
    - Format MUST match ask; prose brief; evidence, verification, blocking details complete.
    - Code/tool/test/doc/source claims MUST be grounded; unobserved claims `[INFERENCE]`.
    - Verification claims exactly match exercised work.
    </evidence-and-output>
    <yielding>
    Before yielding: all affected callsites/tests/docs updated or intentionally unchanged; output/evidence requirements satisfied.
    Before blocked: ensure info unreachable via tools/context; one failed check ≠ blocked. Finish reachable work; state exactly missing and tried.
    </yielding>
    § Critical
    <critical>
    - NEVER yield while actionable work remains; phase boundary/todo flip/sub-step never stops: same turn.
    - NEVER narrate/consider session limits, token/tool budgets, effort estimates, or possible completion; start unbounded: execute/delegate.
    - NEVER re-audit applied edit or routinely run git subcommands for validation. Tool results are verification.
    </critical>
  '';

  # pi-permission-system 策略：OS 沙盒(bwrap)之上的审批层，映射 codex 的
  # approval_policy + 信任级别。路径保护 + bash 模式 + 工作区边界门。
  # authorizerChain 启用 "auto-review"（pi-permission-auto-review）：
  # 模型按 Codex Guardian 策略评估，潜在危险时询问。
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
    piPython
    playwright-driver.browsers
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
