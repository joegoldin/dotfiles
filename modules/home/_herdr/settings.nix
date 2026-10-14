{ config }:
let
  pluginBinding = key: command: description: {
    inherit key command description;
    type = "plugin_action";
  };
in
[
  {
    path = "${config.xdg.configHome}/herdr/config.toml";
    settings = {
      ui = {
        prompt_new_tab_name = false;
        status_indicators = "symbols";
        toast.delivery = "terminal";
        # $vcs from the auto-title fork in place of the built-in branch, which
        # reads only git and so is empty in a jj repo.
        sidebar.spaces.rows = [
          [
            "state_icon"
            "workspace"
          ]
          [
            "$vcs"
            "git_status"
          ]
        ];
      };
      # Ghostty's Gruvbox Dark Hard, not Herdr's softer built-in background.
      theme = {
        name = "gruvbox";
        auto_switch = false;
        custom = {
          panel_bg = "#1d2021";
          sidebar_bg = "#1d2021";
          surface_dim = "#1d2021";
          selection_bg = "#665c54";
        };
      };
      keys = {
        # Linux ctrl+shift and macOS cmd chords; Ghostty unbinds them and keeps
        # its own tab and window actions on ctrl+shift+alt.
        new_tab = [
          "ctrl+shift+t"
          "cmd+t"
          "prefix+c"
        ];
        new_workspace = [
          "ctrl+shift+n"
          "cmd+n"
          "prefix+shift+n"
        ];
        # A pane, not the tab, so one chord cannot take down a tab of agents.
        close_pane = [
          "ctrl+shift+w"
          "cmd+w"
          "prefix+x"
        ];
        split_vertical = [
          "ctrl+shift+o"
          "cmd+d"
          "prefix+v"
        ];
        split_horizontal = [
          "ctrl+shift+e"
          "cmd+shift+d"
          "prefix+minus"
        ];
        next_tab = [
          "ctrl+tab"
          "prefix+n"
        ];
        previous_tab = [
          "ctrl+shift+tab"
          "prefix+p"
        ];
        switch_tab = [
          "alt+1..9"
          "cmd+1..9"
          "prefix+1..9"
        ];
        focus_pane_left = [
          "ctrl+alt+left"
          "prefix+h"
        ];
        focus_pane_down = [
          "ctrl+alt+down"
          "prefix+j"
        ];
        focus_pane_up = [
          "ctrl+alt+up"
          "prefix+k"
        ];
        focus_pane_right = [
          "ctrl+alt+right"
          "prefix+l"
        ];
        previous_workspace = "ctrl+alt+shift+tab";
        next_workspace = "ctrl+alt+tab";
        command = [
          (pluginBinding "prefix+E" "ttt.editor.open" "open TTT editor")
          (pluginBinding "prefix+R" "herdr.auto-title.restart" "restart auto title")
        ];
      };
    };
  }
]
