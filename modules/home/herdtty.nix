_: {
  den.aspects.herdtty.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      shared = import ./ghostty/_settings.nix { inherit lib; };
      sharedConfig =
        if isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/com.mitchellh.ghostty/config"
        else
          "${config.xdg.configHome}/ghostty/config";
      terminalLauncher = pkgs.writeShellScriptBin "herdtty-terminal" ''
        exec ${pkgs.herdtty}/bin/herdtty --herdr-terminal=true "$@"
      '';
      settings = {
        herdr = true;
        herdr-remote = if isDarwin then [ "elphael=elphael" ] else [ "torrent=torrent" ];
        keybind = [
          "ctrl+shift+alt+arrow_up=drill_up"
          "ctrl+shift+alt+arrow_down=drill_down"
          "ctrl+shift+alt+w=pop_out_workspace"
          "ctrl+shift+alt+t=pop_out_tab"
          "ctrl+shift+alt+b=toggle_workspace_sidebar"
          "ctrl+shift+alt+arrow_left=previous_workspace"
          "ctrl+shift+alt+arrow_right=next_workspace"
          "ctrl+shift+alt+x=close_workspace"
          "shift+enter=unbind"
        ];
      };
    in
    {
      home = {
        packages = [ pkgs.herdtty ] ++ lib.optional (!isDarwin) terminalLauncher;
        sessionVariables.TERMINAL =
          if isDarwin then
            "${pkgs.herdtty}/bin/herdtty-terminal"
          else
            "${terminalLauncher}/bin/herdtty-terminal";

        activation.herdttyLocalApps = lib.mkIf isDarwin (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ${pkgs.herdtty}/bin/herdtty-build-local
          ''
        );
        activation.herdttyDefaultTerminal = lib.mkIf isDarwin (
          lib.hm.dag.entryAfter [ "linkGeneration" "herdttyLocalApps" ] ''
            run /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
              -f "${config.home.homeDirectory}/Applications/herdtty Terminal.app"
            run ${pkgs.duti}/bin/duti -s dev.herdtty.terminal public.unix-executable all
          ''
        );
      };

      # Includes load after the root file, so keep overrides in the final include.
      xdg.configFile."herdtty/config".text = shared.toGhosttyConfig {
        config-file = [
          sharedConfig
          "${config.xdg.configHome}/herdtty/bindings"
        ];
      };
      xdg.configFile."herdtty/bindings".text = shared.toGhosttyConfig settings;
    };
}
