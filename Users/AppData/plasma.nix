{lib, ...}: let
  assets = ./assets;
  lockWallpaper = assets + /wallpapers/v2-76efa32deb7d299c06b3ddf5735f81ac_r.png;
in {
  # overrideConfig advisory:
  # Keep programs.plasma.overrideConfig disabled while testing this migration.
  # Enabling it makes Plasma configuration fully declarative by deleting/resetting
  # unmanaged KDE settings during activation. Turn it on only after this module is
  # proven complete for your session, panels, shortcuts, wallpaper plugins, and
  # application-specific settings.
  programs.plasma = {
    enable = true;
    overrideConfig = false;

    # Workspace: global theme, Plasma style, color scheme, icons, cursor, and wallpaper.
    workspace = {
      theme = "Scratchy";
      colorScheme = "CatppuccinMochaFlamingo";
      lookAndFeel = "org.kde.breezedark.desktop";
      iconTheme = "Cobalt-dark";
      cursor.theme = "WhiteSur-cursors";
      wallpaper = lockWallpaper;
    };

    # Panels: translated manually from plasma-org.kde.plasma.desktop-appletsrc.
    panels = [
      {
        height = 28;
        location = "bottom";
        screen = 0;
        hiding = "autohide";
        lengthMode = "custom";
        minLength = 2160;
        maxLength = 2160;
        offset = 0;
        floating = false;
        opacity = "adaptive";
        widgets = [
          {
            kickoff = {
              icon = "nix-snowflake-white";
              label = "Start";
              sortAlphabetically = true;
              applicationsDisplayMode = "grid";
              showButtonsFor = "powerAndSession";
              showActionButtonCaptions = false;
              popupHeight = 505;
              popupWidth = 645;
              settings.General.favoritesPortedToKAstats = true;
            };
          }
          "org.kde.plasma.panelspacer"
          {
            systemTray = {
              items.extra = [
                "org.kde.plasma.battery"
                "org.kde.plasma.brightness"
                "org.kde.plasma.cameraindicator"
                "org.kde.plasma.clipboard"
                "org.kde.plasma.devicenotifier"
                "org.kde.plasma.manage-inputmethod"
                "org.kde.plasma.mediacontroller"
                "org.kde.plasma.notifications"
                "org.kde.kscreen"
                "org.kde.plasma.keyboardindicator"
                "org.kde.plasma.keyboardlayout"
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.volume"
                "org.kde.plasma.weather"
                "org.kde.kdeconnect"
              ];
              items.shown = ["KGpg"];
              items.configs."org.kde.plasma.weather".config = {
                Appearance = {
                  showTemperatureInBadge = true;
                  showTemperatureInCompactMode = true;
                };
                Units = {
                  pressureUnit = 5007;
                  speedUnit = 9000;
                  temperatureUnit = 6001;
                  visibilityUnit = 2007;
                };
                WeatherStation = {
                  placeDisplayName = "Shenzhen, China, CN";
                  placeInfo = "Shenzhen, China, CN|1795565";
                  provider = "bbcukmet";
                };
              };
            };
          }
          "org.kde.plasma.marginsseparator"
          {
            digitalClock = {
              date.format = "isoDate";
              font = {
                family = "SFNS Display";
                size = 15;
              };
              settings.Appearance = {
                customSpacing = 1.7171717171717171;
                enabledCalendarPlugins = "/usr/lib/qt5/plugins/plasmacalendarplugins/holidaysevents.so,holidaysevents,alternatecalendar";
                fixedFont = true;
              };
            };
          }
        ];
      }
      {
        height = 28;
        location = "top";
        screen = 0;
        hiding = "autohide";
        floating = false;
        lengthMode = "custom";
        minLength = 540;
        maxLength = 895;
        offset = 0;
        widgets = [
          {
            iconTasks = {
              iconsOnly = false;
              settings.General = {
                groupedTaskVisualization = 1;
                launchers = "";
              };
            };
          }
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    # Desktop containment: folder view and mouse actions.
    desktop = {
      icons = {
        alignment = "right";
        sorting.mode = "manual";
      };
      mouseActions = {
        middleClick = "applicationLauncher";
        rightClick = "contextMenu";
      };
    };

    # KWin: native options for the standard window-manager settings.
    kwin = {
      effects = {
        blur = {
          enable = true;
          strength = 13;
        };
        dimAdminMode.enable = true;
        minimization = {
          animation = "magiclamp";
          duration = 300;
        };
        shakeCursor.enable = false;
        translucency.enable = true;
        windowOpenClose.animation = "glide";
      };
      nightLight.enable = true;
      virtualDesktops = {
        number = 2;
        rows = 1;
      };
      tiling = {
        padding = 4;
        layout = {
          id = "769c77b7-3750-4f4b-bcba-40aca91ef951";
          tiles = {
            layoutDirection = "horizontal";
            tiles = [
              {width = 0.25;}
              {width = 0.5;}
              {width = 0.25;}
            ];
          };
        };
      };
    };

    # Shortcuts: only non-default meaningful shortcuts from kglobalshortcutsrc.
    shortcuts = {
      "kwin"."ExposeAll" = ["Ctrl+F10" "Launch (C)"];
      "kwin"."Grid View" = ["Meta+Tab" "Meta+G"];
      "kwin"."Switch to Desktop 1" = "Ctrl+F1";
      "kwin"."Switch to Desktop 2" = "Ctrl+F2";
      "kwin"."Switch to Desktop 3" = "Ctrl+F3";
      "kwin"."Switch to Desktop 4" = "Ctrl+F4";
      "kwin"."Walk Through Windows" = "Alt+Tab";
      "kwin"."Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
      "kwin"."Walk Through Windows of Current Application" = "Alt+`";
      "kwin"."Walk Through Windows of Current Application (Reverse)" = "Alt+~";
      "plasmashell"."activate application launcher" = "Meta";
      "plasmashell"."next activity" = "Meta+A";
      "plasmashell"."previous activity" = "Meta+Shift+A";
      "services/org.kde.touchpadshortcuts.desktop"."ToggleTouchpad" = [
        "Touchpad Toggle"
        "Meta+Ctrl+Zenkaku Hankaku"
      ];
    };

    # Custom hotkey commands: khotkeysrc was absent in the backup.
    hotkeys.commands = {};

    # Input: keyboard layout is native; repeat and generic X11 mouse flags fall back below.
    input.keyboard.layouts = [
      {layout = "us";}
    ];

    # Fonts from kdeglobals.
    fonts = {
      general = {
        family = "Noto Sans";
        pointSize = 10;
      };
      fixedWidth = {
        family = "Maple Mono NF CN";
        pointSize = 10;
      };
      menu = {
        family = "Noto Sans";
        pointSize = 10;
      };
      small = {
        family = "Noto Sans";
        pointSize = 8;
      };
      toolbar = {
        family = "Noto Sans";
        pointSize = 10;
      };
      windowTitle = {
        family = "Noto Sans";
        pointSize = 10;
      };
    };

    krunner.shortcuts.launch = [
      "Alt+Space"
      "Search"
    ];

    kscreenlocker.appearance.wallpaper = lockWallpaper;

    spectacle.shortcuts = {
      captureEntireDesktop = "Print";
      captureRectangularRegion = "Alt+F1";
      launch = "Meta+Shift+S";
    };

    # Fallback: rc keys without native plasma-manager equivalents, or where the
    # native option cannot preserve the exact original semantics.
    configFile = {
      "kdeglobals" = {
        "General" = {
          AccentColor = "202,165,246";
          LastUsedCustomAccentColor = "202,165,246";
          TerminalApplication = "kitty";
          TerminalService = "kitty.desktop";
          XftHintStyle = "hintslight";
          XftSubPixel = "none";
        };
        "KDE" = {
          AnimationDurationFactor = 0.5;
          ShowDeleteCommand = false;
          widgetStyle = "Klassy";
        };
        "KFileDialog Settings" = {
          "Allow Expansion" = false;
          "Automatically select filename extension" = true;
          "Breadcrumb Navigation" = false;
          "Decoration position" = 2;
          "Show Full Path" = false;
          "Show Inline Previews" = true;
          "Show Preview" = false;
          "Show Speedbar" = true;
          "Show hidden files" = false;
          "Sort by" = "Date";
          "Sort directories first" = true;
          "Sort hidden files last" = false;
          "Sort reversed" = false;
          "Speedbar Width" = 140;
          "View Style" = "DetailTree";
        };
        "KScreen" = {
          ScaleFactor = 1.5;
          ScreenScaleFactors = "DP-2=1.5;";
        };
        "KShortcutsDialog Settings"."Dialog Size" = "600,480";
        "PreviewSettings" = {
          EnableRemoteFolderThumbnail = false;
          MaximumRemoteSize = 0;
        };
      };

      "kwinrc" = {
        "Effect-blurplus" = {
          BlurStrength = 10;
          BottomCornerRadius = 5;
          DockCornerRadius = 6;
          MenuCornerRadius = 6;
          NoiseStrength = 1;
          TopCornerRadius = 6;
          WindowClasses = "firefox";
        };
        "Effect-login".FadeToBlack = true;
        "Effect-overview".BorderActivate = 9;
        "Effect-trackmouse".Meta = false;
        "Effect-translucency" = {
          Inactive = 10;
          MoveResize = 100;
        };
        "Effect-windowview".BorderActivateAll = 5;
        "ElectricBorders".BottomRight = "ShowDesktop";
        "IncludeExclude".Exclusions = "cs2";
        "Plugins" = {
          contrastEnabled = true;
          "fcitx-auto-switchEnabled" = false;
          eyeonscreenEnabled = true;
          kwin4_effect_lightlyshadersEnabled = true;
          kwin_effect_lightlyshadersEnabled = false;
          lightlyshaders_blurEnabled = false;
          minecraft_keyrepeatEnabled = true;
          morphingpopupsEnabled = false;
          screenedgeEnabled = false;
          sheetEnabled = true;
          tileseditorEnabled = false;
          windowapertureEnabled = false;
          windowviewEnabled = false;
        };
        "PrimaryOutline" = {
          ActiveOutlinePalette = 7;
          InactiveOutlineColor = "55,55,69";
          InactiveOutlinePalette = 7;
          InactiveOutlineThickness = 0.8;
          OutlineColor = "55,55,69";
          OutlinePalette = 7;
          OutlineThickness = 0.8;
        };
        "Round-Corners" = {
          ActiveOutlineAlpha = 255;
          ActiveOutlinePalette = 10;
          ActiveOutlineUseCustom = false;
          ActiveOutlineUsePalette = true;
          Exclusions = "com.usebottles.bottles,com.github.neithern.g4music,com.github.wwmm.easyeffects,eu.ithz.umftpd,Galaxy Flasher,tsukimi";
          InactiveCornerRadius = 8;
          InactiveOutlineAlpha = 255;
          InactiveOutlineColor = "46,46,46";
          InactiveOutlinePalette = 10;
          InactiveOutlineThickness = 0.75;
          InactiveOutlineUseCustom = false;
          InactiveOutlineUsePalette = true;
          InactiveSecondOutlineColor = "46,46,46";
          InactiveSecondOutlineThickness = 1.48;
          OutlineColor = "46,46,46";
          OutlineThickness = 0.75;
          SecondOutlineColor = "46,46,46";
          SecondOutlineThickness = 1.48;
          Size = 8;
        };
        "SecondOutline" = {
          ActiveSecondOutlinePalette = 7;
          InactiveSecondOutlineColor = "55,55,69";
          InactiveSecondOutlinePalette = 7;
          InactiveSecondOutlineThickness = 1.01;
          SecondOutlineColor = "55,55,69";
          SecondOutlineThickness = 1.01;
        };
        "Shadow" = {
          ActiveShadowAlpha = 43;
          InactiveShadowAlpha = 43;
        };
        "Wayland" = {
          "InputMethod[$e]" = "/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop";
          VirtualKeyboardEnabled = true;
        };
        "Windows_HDR" = {
          MaxFrameAverage = 0;
          MaxLuminance = 440;
          Reference = 180;
        };
        "Xwayland" = {
          Scale = 1.5;
          XwaylandEavesdrops = "None";
        };
        "org.kde.kdecoration2" = {
          BorderSize = "Normal";
          BorderSizeAuto = false;
          library = "org.kde.klassy";
          theme = "Klassy";
        };
        "ًRound-Corners" = {
          AnimationEnabled = false;
          InactiveCornerRadius = 8;
          InactiveShadowColor = "255,255,255";
          InactiveShadowSize = 38;
          ShadowColor = "255,255,255";
          ShadowSize = 38;
          Size = 8;
        };
      };

      "kcminputrc" = {
        "Keyboard".Repeat = false;
        "Mouse".X11LibInputXAccelProfileFlat = true;
      };

      "kscreenlockerrc"."Greeter/Wallpaper/org.kde.image/General".PreviewImage = toString lockWallpaper;

      "plasma-localerc"."Formats".LANG = "en_US.UTF-8";

      "plasmarc"."Wallpapers".usersWallpapers = lib.concatStringsSep "," [
        "${assets}/wallpapers/泉此方.jpg"
        "${assets}/wallpapers/泉此方 brightness.kra"
        "${assets}/wallpapers/泉此方 brightness.avif"
        "${lockWallpaper}"
      ];

      "kactivitymanagerdrc"."activities"."470c04e6-c8d0-4263-a634-8b92fc2f317a" = "Default";

      "katerc" = {
        "General" = {
          "Days Meta Infos" = 30;
          PinnedDocuments = "";
          "Save Meta Infos" = true;
          "Show Full Path in Title" = false;
          "Show Menu Bar" = true;
          "Show Status Bar" = true;
          "Show Tab Bar" = true;
          "Show Url Nav Bar" = true;
        };
        "KTextEditor Renderer" = {
          "Auto Color Theme Selection" = true;
          "Color Theme" = "Catppuccin Mocha";
          "Line Height Multiplier" = 1;
          "Show Whole Bracket Expression" = false;
          "Text Font Features" = "";
          "Word Wrap Marker" = false;
        };
        "Konsole" = {
          AutoSyncronizeMode = 0;
          KonsoleEscKeyBehaviour = true;
          KonsoleEscKeyExceptions = "vi,vim,nvim,git";
          RemoveExtension = false;
          RunPrefix = "";
          SetEditor = false;
        };
        "filetree" = {
          editShade = "31,81,106";
          listMode = false;
          middleClickToClose = false;
          shadingEnabled = true;
          showCloseButton = false;
          showFullPathOnRoots = false;
          showToolbar = true;
          sortRole = 0;
          viewShade = "81,49,95";
        };
        "lspclient" = {
          AllowedServerCommandLines = "";
          AutoHover = true;
          AutoImport = true;
          BlockedServerCommandLines = "";
          CompletionDocumentation = true;
          CompletionParens = true;
          Diagnostics = true;
          FormatOnSave = false;
          HighlightGoto = true;
          IncrementalSync = false;
          InlayHints = false;
          Messages = true;
          ReferencesDeclaration = true;
          SemanticHighlighting = true;
          ServerConfiguration = "";
          SignatureHelp = true;
          SymbolDetails = false;
          SymbolExpand = true;
          SymbolSort = false;
          SymbolTree = true;
          TypeFormatting = false;
        };
      };
    };
  };

  programs.kate = {
    enable = true;
    package = null;
    editor = {
      font = {
        family = "Hack";
        pointSize = 10;
      };
      indent.showLines = false;
      brackets.flashMatching = false;
    };
  };
}
