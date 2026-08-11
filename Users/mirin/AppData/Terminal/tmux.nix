{...}: {
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    extraConfig = ''
      set -g status on
      set -g status-position bottom
      set -g status-interval 5
      set -g status-style "bg=#1e1e2e,fg=#ffffff"
      set -g status-left-length 32
      set -g status-right-length 80
      set -g window-status-separator ""

      set -g pane-border-style "fg=#5BCEFA"
      set -g pane-active-border-style "fg=#F5A9B8"
      set -g message-style "bg=#F5A9B8,fg=#1e1e2e,bold"
      set -g mode-style "bg=#5BCEFA,fg=#1e1e2e,bold"

      set -g status-left "#[fg=#000000,bg=#FFFFFF,bold] + "
      set -g window-status-format "#{?#{==:#{window_start_flag},1},,#[fg=#F5A9B8]#[bg=#FFFFFF]}#[fg=#1e1e2e,bg=#FFFFFF] #I #[fg=#FFFFFF,bg=#F5A9B8]#[fg=#1e1e2e,bg=#F5A9B8] #W #{?#{==:#{window_end_flag},1},#[fg=#F5A9B8]#[bg=#1e1e2e],}"
      set -g window-status-current-format "#{?#{==:#{window_start_flag},1},#[fg=#FFFFFF],#[fg=#F5A9B8]}#[bg=#5BCEFA]#[fg=#1e1e2e,bg=#5BCEFA,bold] #I #[fg=#5BCEFA,bg=#F5A9B8]#[fg=#1e1e2e,bg=#F5A9B8,bold] #W #{?#{==:#{window_end_flag},1},#[fg=#F5A9B8]#[bg=#1e1e2e],}"
      set -g status-right "#[fg=#5BCEFA,bg=#1e1e2e]#[fg=#1e1e2e,bg=#5BCEFA,bold] clients #{session_attached} #[fg=#F5A9B8,bg=#5BCEFA]#[fg=#1e1e2e,bg=#F5A9B8,bold] %Y-%m-%d %H:%M "

      set -g xterm-keys on
      set -g extended-keys on

      bind-key -n MouseDown1StatusLeft new-window
      bind-key c new-window
      bind-key r source-file ~/.tmux.conf \; display-message "tmux config reloaded"
    '';
  };
}
