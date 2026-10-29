# Match the shared Ghostty font and the Mac's size override. Other Rex app
# preferences (layout, sidebar, imported themes, etc.) remain user-owned.
{

  den.aspects.rex.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ghostty = (import ../../home/ghostty/_settings.nix { inherit lib; }).baseSettings;
    in
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin.defaults."com.superlogical.rex" = {
        "Workspace.terminalFontName" = ghostty.font-family;
        "Workspace.terminalFontPointSize" = 13.0;
        "Workspace.terminalCopyOnSelect" = ghostty.copy-on-select;
        "Workspace.terminalStartupCommand" = "/etc/profiles/per-user/joe/bin/fish";
        "Workspace.terminalUseThemePalette" = true;
      };
      xdg.configFile."rex/themes/Gruvbox Dark Hard".source = ../../home/_rex/gruvbox-dark-hard;
      home.activation = {
        # Restore native shortcuts, including on Macs with our old Ctrl+Shift overrides.
        rexClipboardShortcuts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run /usr/bin/defaults write com.superlogical.rex NSUserKeyEquivalents \
            -dict-add Copy '@c' Paste '@v'
        '';
        rexTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          run ${pkgs.python3}/bin/python3 ${../../home/_rex/import-theme.py} \
            '/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex' \
            ${lib.escapeShellArg "${config.xdg.configHome}/rex/themes/Gruvbox Dark Hard"} \
            ${lib.escapeShellArg "${config.xdg.stateHome}/rex/dotfiles-theme.sha256"}
        '';
      };
    };
}
