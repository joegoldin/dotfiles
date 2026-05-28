{
  pkgs,
  lib,
  config,
  ...
}:
let
  qdbus = "${pkgs.kdePackages.qttools}/bin/qdbus";

  mouseActionsConfig = {
    shape_button = "Right";
    bindings = [
      # Draw Z shape → launch zeditor (text editor)
      {
        event = {
          button = "Right";
          edges = [ ];
          modifiers = [ ];
          event_type = "Click";
          shape = [
            0.0 0.0 0.0 0.0 0.0 0.0 (-0.05) (-0.05) (-0.06) (-0.04) (-0.03) (-0.02) (-0.02) (-0.02) (-0.03) (-0.03)
            (-0.05) (-0.05) (-0.06) (-0.06) (-0.08) (-0.08) (-0.1) (-0.1) (-0.14) (-0.14) (-0.25) (-0.25) (-0.58) (-0.58) (-1.51)
            (-1.51) (-2.12) (-2.12) (-2.48) (-2.48) (-2.54) (-2.54) (-2.59) (-2.59) (-2.62) (-2.62) (-2.64) (-2.64) (-2.63) (-2.63)
            (-2.62) (-2.62) (-2.61) (-2.61) (-2.59) (-2.59) (-2.59) (-2.55) (-2.55) (-2.51) (-2.47) (-2.47) (-2.35) (-2.35) (-2.18)
            (-2.18) (-2.18) (-1.65) (-1.65) (-0.81) (-0.81) (-0.46) (-0.46) (-0.3) (-0.2) (-0.2) (-0.2) (-0.15) (-0.11) (-0.08)
            (-0.07) (-0.07) (-0.07)
          ];
        };
        cmd = [ "zeditor" ];
      }

      # Draw T shape → launch the terminal (ghostty)
      {
        event = {
          button = "Right";
          edges = [ ];
          modifiers = [ ];
          event_type = "Click";
          shape = [
            (-0.46) (-0.11) (-0.11) (-0.22) (-0.09) (-0.05) (-0.04) (-0.04) 0.04 0.04 0.05 0.05 0.11 0.11 0.12 0.12
            0.13 0.13 0.14 0.14 0.16 0.16 0.17 0.17 0.18 0.18 0.16 0.16 0.15 0.15 0.14 0.15 0.15 0.15
            0.13 0.13 0.11 0.11 (-0.08) (-0.08) (-0.08) (-0.75) (-0.75) (-1.64) (-1.64) (-2.09) (-2.09) (-2.2) (-2.2) (-2.21)
            (-2.21) (-2.21) (-2.11) (-2.11) (-2.05) (-2.05) (-1.96) (-1.96) (-1.84) (-1.8) (-1.73) (-1.73) (-1.71) (-1.68) (-1.67)
            (-1.66) (-1.65) (-1.65) (-1.65) (-1.65) (-1.65) (-1.65)
          ];
        };
        cmd = [ "ghostty" ];
      }

      # Draw V shape → KDE Plasma Overview
      {
        event = {
          button = "Right";
          edges = [ ];
          modifiers = [ ];
          event_type = "Click";
          shape = [
            (-1.57) (-1.57) (-1.57) (-1.23) (-1.23) (-1.15) (-1.15) (-1.11) (-1.11) (-1.02) (-1.02) (-1.0) (-1.0) (-0.99) (-0.99)
            (-0.96) (-0.96) (-0.98) (-0.98) (-0.95) (-0.95) (-0.92) (-0.92) (-0.88) (-0.81) (-0.77) (-0.77) (-0.65) (-0.65) (-0.48)
            (-0.48) (-0.1) (-0.1) 0.22 0.22 0.49 0.49 0.7 0.7 0.74 0.74 0.83 0.83 0.85 0.85 0.82 0.82
          ];
        };
        cmd = [
          qdbus
          "org.kde.kglobalaccel"
          "/component/kwin"
          "org.kde.kglobalaccel.Component.invokeShortcut"
          "Overview"
        ];
      }

      # Draw ∝ (alpha) shape → Ctrl+X key (cut)
      {
        event = {
          button = "Right";
          edges = [ ];
          modifiers = [ ];
          event_type = "Click";
          shape = [
            (-1.57) (-1.57) (-1.69) (-1.69) (-1.76) (-1.76) (-1.92) (-1.92) (-1.99) (-1.99) (-2.05) (-2.05) (-2.12) (-2.12) (-2.16)
            (-2.16) (-2.2) (-2.2) (-2.25) (-2.25) (-2.3) (-2.3) (-2.37) (-2.37) (-2.45) (-2.45) (-2.53) (-2.53) (-2.62) (-2.62)
            (-2.71) (-2.78) (-2.84) (-2.84) (-2.92) (-2.92) (-2.98) (-2.98) (-3.04) (-3.04) (-3.13) (-3.13) 3.06 3.06 2.94
            2.94 2.8 2.8 2.67 2.67 2.53 2.53 2.24 2.24 1.89 1.89 1.44 1.44 0.95 0.58 0.58 0.31 0.31
            0.18 0.18 0.01 0.01 (-0.09) (-0.09) (-0.23) (-0.23) (-0.23) (-0.31) (-0.31) (-0.39) (-0.39) (-0.46) (-0.46)
            (-0.55) (-0.55) (-0.61) (-0.61) (-0.61) (-0.66) (-0.66) (-0.69) (-0.69) (-0.7) (-0.7) (-0.71) (-0.71) (-0.72) (-0.72)
            (-0.72) (-0.72) (-0.72) (-0.74) (-0.74)
          ];
        };
        cmd = [ "xdotool" "key" "ctrl+x" ];
      }
    ];
  };

  mouseActionsConfigFile = pkgs.writeText "mouse-actions.json" (
    builtins.toJSON mouseActionsConfig
  );
in
{
  home.packages = with pkgs; [
    mouse-actions
    # nixpkgs' mouse-actions-gui is marked broken because Tauri v1 needs
    # webkit2gtk-4.0, which was removed from nixpkgs. Use upstream's AppImage
    # (which bundles webkit2gtk-4.0) until upstream migrates to Tauri v2.
    mouse-actions-gui-appimage
    xdotool
  ];

  # Copy the config into place instead of symlinking so the GUI can still
  # edit it between rebuilds. Each switch overwrites on-disk edits with the
  # in-tree config — the in-tree nix attrset is the source of truth.
  home.activation.mouseActionsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.xdg.configHome}
    rm -f ${config.xdg.configHome}/mouse-actions.json
    install -m644 ${mouseActionsConfigFile} ${config.xdg.configHome}/mouse-actions.json
  '';
}
