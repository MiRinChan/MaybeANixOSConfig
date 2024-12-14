{
  config,
  pkgs,
  ...
}: {
  # zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtra = ''
      export ALL_PROXY=socks5://127.0.0.1:2080 && export HTTP_PROXY=http://127.0.0.1:2080 && export HTTPS_PROXY=http://127.0.0.1:2080 && echo "Hello."
    '';

    shellAliases = {
      rebuild = "sudo nixos-rebuild switch";
      proxy = "export ALL_PROXY=socks5://127.0.0.1:2080 && export HTTP_PROXY=http://127.0.0.1:2080 && export HTTPS_PROXY=http://127.0.0.1:2080";
      deproxy = "unset ALL_PROXY && unset HTTP_PROXY && unset HTTPS_PROXY";
      btw = ''echo "I'm using..." && hyfetch'';
      neofetch = "hyfetch";
      ls = "eza";

      # My personal config
      vm = ''VBoxManage startvm "{d58d055c-e878-46bb-9c7f-d8b444a0e10b}" --type headless'';
      vmpf = ''VBoxManage controlvm "{d58d055c-e878-46bb-9c7f-d8b444a0e10b}" acpipowerbutton'';
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "thefuck" "direnv"];
      theme = "";
    };
  };
  programs.kitty = {
    enable = true;
    font.name = "Maple Mono SC NF";
    settings = {
      confirm_os_window_close = 0;
      dynamic_background_opacity = true;
      enable_audio_bell = false;
      mouse_hide_wait = "-1.0";
      window_padding_width = 10;
      # background_opacity = "0.95";
      # background_blur = 20;
    };
    extraConfig = with config.stylix.base16Scheme; ''

      # The basic colors
      foreground              #cdd6f4
      background              #1e1e2e
      selection_foreground    #1e1e2e
      selection_background    #f5e0dc

      # Cursor colors
      cursor                  #f5e0dc
      cursor_text_color       #1e1e2e

      # URL underline color when hovering with mouse
      url_color               #f5e0dc

      # Kitty window border colors
      active_border_color     #b4befe
      inactive_border_color   #6c7086
      bell_border_color       #f9e2af

      # OS Window titlebar colors
      wayland_titlebar_color system
      macos_titlebar_color system

      # Tab bar colors
      active_tab_foreground   #11111b
      active_tab_background   #cba6f7
      inactive_tab_foreground #cdd6f4
      inactive_tab_background #181825
      tab_bar_background      #11111b

      # Colors for marks (marked text in the terminal)
      mark1_foreground #1e1e2e
      mark1_background #b4befe
      mark2_foreground #1e1e2e
      mark2_background #cba6f7
      mark3_foreground #1e1e2e
      mark3_background #74c7ec

      # The 16 terminal colors

      # black
      color0 #45475a
      color8 #585b70

      # red
      color1 #f38ba8
      color9 #f38ba8

      # green
      color2  #a6e3a1
      color10 #a6e3a1

      # yellow
      color3  #f9e2af
      color11 #f9e2af

      # blue
      color4  #89b4fa
      color12 #89b4fa

      # magenta
      color5  #f5c2e7
      color13 #f5c2e7

      # cyan
      color6  #94e2d5
      color14 #94e2d5

      # white
      color7  #bac2de
      color15 #a6adc8
    '';
  };
  programs.starship = {
    enable = true;
    settings.character = {
      success_symbol = "[](fg:#1E1E2E bg:#5BCEFA)[](fg:#5BCEFA bg:#F5A9B8)[](fg:#F5A9B8 bg:#FFFFFF)[](fg:#FFFFFF bg:#F5A9B8)[](fg:#F5A9B8 bg:#5BCEFA)[](#5BCEFA)";
      error_symbol = "[](fg:#1E1E2E bg:red)[](fg:red bg:red)[](red)";
    };
    enableTransience = true;
  };
  programs.thefuck.enable = true;

  programs.hyfetch = {
    enable = true;
    settings = {
      preset = "transgender";
      mode = "rgb";
      light_dark = "dark";
      lightness = 0.65;
      color_align = {
        mode = "horizontal";
        # custom_colors = [];
        # fore_back = null;
      };
      backend = "fastfetch";
      # args = null;
      # distro = null;
      # pride_month_shown = [];
      # pride_month_disable = false;
    };
  };
}
