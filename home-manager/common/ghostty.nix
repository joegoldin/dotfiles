{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.ghostty = {
    enable = true;

    # Enable shell integration for available shells
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = false;

    settings = {
      # Font Configuration
      font-family = "TX02 Nerd Font";
      font-size = 12;

      # Enable ligatures
      font-feature = [
        "calt"  # Contextual alternates (programming ligatures)
        "liga"  # Standard ligatures
        "dlig"  # Discretionary ligatures
      ];

      # Theme
      theme = "Gruvbox Dark Hard";

      # Window Configuration
      window-decoration = true;
      window-padding-x = 4;
      window-padding-y = 4;
      window-padding-balance = true;
      window-inherit-working-directory = true;
      window-inherit-font-size = true;

      # Performance
      window-vsync = true;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;
      cursor-click-to-move = true;

      # Mouse
      mouse-hide-while-typing = true;
      copy-on-select = "clipboard";

      # Clipboard
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-trim-trailing-spaces = true;
      clipboard-paste-protection = true;

      # Scrollback
      scrollback-limit = 100000;

      # Shell Integration
      shell-integration = "fish";
      shell-integration-features = "cursor,sudo,title";

      # Background/Transparency (optional, uncomment if desired)
      background-opacity = 0.95;

      # Keybindings (sane defaults)
      keybind = [
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+shift+t=new_tab"
        "ctrl+shift+w=close_surface"
        "ctrl+shift+n=new_window"
        "shift+enter=text:\\x1b\\r"
      ];
    };
  };
}
