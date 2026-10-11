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
        status_indicators = "symbols";
        toast.delivery = "terminal";
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
        next_tab = [
          "ctrl+shift+tab"
          "prefix+n"
        ];
        previous_tab = "prefix+p";
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
          (pluginBinding "prefix+N" "herdr-navigator.open" "workspace navigator")
          (pluginBinding "prefix+E" "ttt.editor.open" "open TTT editor")
          (pluginBinding "prefix+R" "herdr.auto-title.restart" "restart auto title")
        ];
      };
    };
  }
]
