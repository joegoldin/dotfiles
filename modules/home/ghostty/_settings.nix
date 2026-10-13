{ lib }:
let
  baseSettings = {
    font-family = "TX02 Nerd Font Mono";
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
    window-height = 30;
    window-width = 112;
    window-vsync = true;
    cursor-style = "block";
    cursor-style-blink = false;
    cursor-click-to-move = true;
    mouse-hide-while-typing = true;
    copy-on-select = false;
    clipboard-read = "allow";
    clipboard-write = "allow";
    clipboard-trim-trailing-spaces = true;
    clipboard-paste-protection = true;
    scrollbar = "system";
    scrollback-limit = 1000000000;
    shell-integration = "fish";
    shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo";
    background-opacity = 0.95;
    # The usual tab/window chords (Linux ctrl+shift, macOS cmd) belong to Herdr;
    # Ghostty's own tabs and windows move to ctrl+shift+alt on both platforms.
    # Herdr asks for the Kitty keyboard protocol, so unbound chords reach it
    # with every modifier intact. One list serves both platforms: unbinding a
    # chord the platform never bound is a no-op.
    keybind = [
      "ctrl+shift+c=copy_to_clipboard"
      "ctrl+shift+v=paste_from_clipboard"
      "ctrl+shift+alt+t=new_tab"
      "ctrl+shift+alt+n=new_window"
      "ctrl+shift+alt+w=close_surface"
      "ctrl+shift+alt+o=new_split:right"
      "ctrl+shift+alt+e=new_split:down"
      "ctrl+shift+alt+arrow_right=next_tab"
      "ctrl+shift+alt+arrow_left=previous_tab"
      "ctrl+shift+t=unbind"
      "ctrl+shift+n=unbind"
      "ctrl+shift+w=unbind"
      "ctrl+shift+o=unbind"
      "ctrl+shift+e=unbind"
      "super+t=unbind"
      "super+n=unbind"
      "super+w=unbind"
      "super+d=unbind"
      "super+shift+d=unbind"
      "ctrl+tab=unbind"
      "ctrl+shift+tab=unbind"
      # Ghostty's goto_split defaults would swallow Herdr's pane focus.
      "ctrl+alt+arrow_left=unbind"
      "ctrl+alt+arrow_down=unbind"
      "ctrl+alt+arrow_up=unbind"
      "ctrl+alt+arrow_right=unbind"
      # Preserve the modifier through Herdr's Kitty keyboard protocol.
      "shift+enter=unbind"
    ]
    # Ghostty binds digits under both the character and the physical key.
    ++ lib.concatMap (
      n:
      let
        i = toString n;
      in
      [
        "ctrl+shift+alt+digit_${i}=goto_tab:${i}"
        "alt+${i}=unbind"
        "alt+digit_${i}=unbind"
        "super+${i}=unbind"
        "super+digit_${i}=unbind"
      ]
    ) (lib.range 1 9);
  };

  toGhosttyConfig =
    settings:
    let
      # toString renders Nix booleans as "1"/"" which Ghostty rejects (e.g.
      # mouse-shift-capture wants true/false), so coerce bools to true/false.
      fmtValue = v: if builtins.isBool v then lib.boolToString v else toString v;
      mkLine =
        key: value:
        if builtins.isList value then
          lib.concatMapStringsSep "\n" (v: "${key} = ${fmtValue v}") value
        else
          "${key} = ${fmtValue value}";
    in
    lib.concatStringsSep "\n" (lib.mapAttrsToList mkLine settings);
in
{
  inherit baseSettings toGhosttyConfig;
}
