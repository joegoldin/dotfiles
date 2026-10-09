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
      keys.command = [
        (pluginBinding "prefix+N" "herdr-navigator.open" "workspace navigator")
        (pluginBinding "prefix+M" "nicosuave.memex.palette" "search agent history")
        (pluginBinding "prefix+E" "ttt.editor.open" "open TTT editor")
        (pluginBinding "prefix+R" "herdr.auto-title.restart" "restart auto title")
      ];
    };
  }
  {
    path = "${config.home.homeDirectory}/.memex/config.toml";
    settings = {
      # Semantic search runs locally; the initial model download contains no transcripts.
      embeddings = "local";
      model = "minilm";
      index_service_web_ui = false;
      index_service_mcp = false;
    };
  }
]
