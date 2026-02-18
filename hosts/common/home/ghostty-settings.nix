{ lib }:
let
  baseSettings = {
    font-family = "TX02 Nerd Font";
    font-size = 11;
    font-feature = [
      "calt"
      "liga"
      "dlig"
    ];
    theme = "Gruvbox Dark Hard";
    window-decoration = true;
    window-padding-x = 4;
    window-padding-y = 4;
    window-padding-balance = true;
    window-inherit-working-directory = true;
    window-inherit-font-size = true;
    window-vsync = true;
    cursor-style = "block";
    cursor-style-blink = false;
    cursor-click-to-move = true;
    mouse-hide-while-typing = true;
    copy-on-select = "clipboard";
    clipboard-read = "allow";
    clipboard-write = "allow";
    clipboard-trim-trailing-spaces = true;
    clipboard-paste-protection = true;
    scrollback-limit = 1000000000;
    shell-integration = "fish";
    shell-integration-features = "cursor,sudo,title";
    background-opacity = 0.95;
    keybind = [
      "ctrl+shift+c=copy_to_clipboard"
      "ctrl+shift+v=paste_from_clipboard"
      "ctrl+shift+t=new_tab"
      "ctrl+shift+w=close_surface"
      "ctrl+shift+n=new_window"
      "shift+enter=text:\\x1b\\r"
    ];
  };

  toGhosttyConfig =
    settings:
    let
      mkLine =
        key: value:
        if builtins.isList value then
          lib.concatMapStringsSep "\n" (v: "${key} = ${toString v}") value
        else
          "${key} = ${toString value}";
    in
    lib.concatStringsSep "\n" (lib.mapAttrsToList mkLine settings);
in
{
  inherit baseSettings toGhosttyConfig;
}
