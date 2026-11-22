# Repackage OpenAI's official Linux ChatGPT payload from
# ilysenko/codex-desktop-linux. The upstream derivation always stages the
# community display name and the blue "C" icon; this wrapper restores the
# official ChatGPT name and icon while keeping the stable `codex-desktop`
# application identity used by its launcher and desktop entry.
{
  lib,
  computerUseUi,
  remoteMobileControl,
  linuxFeatures,
  upstream,
}: let
  defaultFeatures = [
    "appshots"
    "chatgpt-dil-markdown-fallback"
    "chatgpt-sidebar-separate-history"
    "codex-micro"
    "wayland-global-shortcuts"
    "node-repl-reaper"
    "pet-overlay"
    "remote-control-ui"
    # Keep Electron's `desktopName` on the installed `codex-desktop.desktop`
    # entry. Without this, launches rewrite `codex://` and notification hints
    # to the absent upstream `chatgpt.desktop` entry.
    "desktop-identity"
    "linux-performance-workarounds"
    "shared-app-server-socket"
  ];

  package = upstream.override {
    enableComputerUseUi = computerUseUi.enable;
    linuxFeatureIds = defaultFeatures ++ linuxFeatures ++ lib.optional remoteMobileControl.enable "remote-mobile-control";
  };

  # Fail the build if the pinned upstream install recipe stops matching, rather
  # than silently producing another community-branded package.
  replaceOnce = from: to: text: let
    parts = lib.splitString from text;
  in
    if builtins.length parts == 1
    then throw "codex-desktop: upstream installPhase fragment not found: ${from}"
    else if builtins.length parts > 2
    then throw "codex-desktop: upstream installPhase fragment is not unique: ${from}"
    else lib.concatStringsSep to parts;

  installPhase = lib.foldl' (text: patch: replaceOnce patch.from patch.to text) package.installPhase [
    {
      # The Linux tray layout snaps the mascot vertically once it crosses the
      # middle of the canvas, which makes the pet jump while it is dragged
      # upward. Keep the tray geometry but drop that snap.
      from = ''chmod -R u+w "$source_dir"'';
      to = ''        chmod -R u+w "$source_dir"
                      sed -i 's/if(g<v&&f>g&&f<v){f=Math.abs(f-g)<=Math.abs(v-f)?g:v,h&&(this.codexPetOverlayMascotLocalPosition={left:m,top:f})}//' "$source_dir/linux-features/pet-overlay/patch.js"
                      if grep -qF 'if(g<v&&f>g&&f<v)' "$source_dir/linux-features/pet-overlay/patch.js"; then
                        echo "codex-desktop: pet tray snap patch did not apply" >&2
                        exit 1
                      fi
                      sed -i 's/"codexPetOverlayTrayAboveLeft(e){[^"]*}"/"codexPetOverlayTrayAboveLeft(e){return e}"/' "$source_dir/linux-features/pet-overlay/patch.js"
                      if ! grep -qF '"codexPetOverlayTrayAboveLeft(e){return e}"' "$source_dir/linux-features/pet-overlay/patch.js"; then
                        echo "codex-desktop: pet tray layout no-op patch did not apply" >&2
                        exit 1
                      fi
                      # KWin clamps the drag position to the layout-derived
                      # display area. That area shrinks once the mascot crosses
                      # the vertical midpoint, producing the same upward jump.
                      sed -i '/x = Math.max(area.x, Math.min(area.maxX, x));/d' "$source_dir/linux-features/pet-overlay/kwin-script.cjs"
                      sed -i '/y = Math.max(area.y, Math.min(area.maxY, y));/d' "$source_dir/linux-features/pet-overlay/kwin-script.cjs"
                      if grep -q 'Math.min(area.maxY, y)' "$source_dir/linux-features/pet-overlay/kwin-script.cjs"; then
                        echo "codex-desktop: pet KWin drag clamp patch did not apply" >&2
                        exit 1
                      fi'';
    }
    {
      # Start scripts and build metadata use this display name.
      from = ''bash "$source_dir/install.sh" --skip-oai-official-sig-verification '';
      to = ''CODEX_APP_DISPLAY_NAME=ChatGPT bash "$source_dir/install.sh" --skip-oai-official-sig-verification '';
    }
    {
      from = ''"$app/.codex-linux/codex-desktop.png"'';
      to = ''"$app/resources/icon-chatgpt.png"'';
    }
    {
      # `stage_community_branding` replaces the signed payload's official
      # icon with the blue "C" variant. Put the official file back both where
      # the launcher/desktop entry expects it and in the staging directory.
      from = ''app="$out/opt/codex-desktop"'';
      to = ''        app="$out/opt/codex-desktop"
                      install -Dm0644 "$upstream_contract_root/usr/lib/chatgpt/resources/icon-chatgpt.png" \
                        "$app/resources/icon-chatgpt.png"
                      install -Dm0644 "$upstream_contract_root/usr/lib/chatgpt/resources/icon-chatgpt.png" \
                        "$app/.codex-linux/codex-desktop.png"'';
    }
    {
      from = ''--replace-fail "/usr/share/applications/codex-desktop.desktop" "$out/share/applications/codex-desktop.desktop"'';
      to = ''        --replace-fail "/usr/share/applications/codex-desktop.desktop" "$out/share/applications/codex-desktop.desktop"
                      substituteInPlace "$out/share/applications/codex-desktop.desktop" \
                        --replace-fail "Name=ChatGPT Community" "Name=ChatGPT" \
                        --replace-fail "Comment=Community Linux distribution based on OpenAI ChatGPT" "Comment=ChatGPT by OpenAI"'';
    }
  ];
in
  package.overrideAttrs (old: {
    # The upstream feature suffix easily exceeds Nix's store-name limit. Keep
    # the readable package identity; the enabled feature list stays in
    # passthru.effectiveLinuxFeatureIds.
    name = "codex-desktop-${package.version}";
    inherit installPhase;
    meta =
      (old.meta or {})
      // {
        description = "OpenAI's official Linux ChatGPT app with selected codex-desktop Linux features";
      };
  })
