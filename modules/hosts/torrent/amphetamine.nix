# Amphetamine "Power Protect" (x74353/Amphetamine-Power-Protect), replicated
# declaratively instead of via its pkg installer. Power Protect lets
# Amphetamine keep a closed-lid MacBook awake by toggling
# `pmset -a disablesleep`; the app drives it through an AppleScript in its
# Application Scripts folder plus a passwordless-sudo rule for exactly those
# two pmset invocations.
{ ... }:
{
  den.aspects.torrent.darwin = {
    # Amphetamine's script probes this exact path (case-sensitive) and
    # silently no-ops if it's absent, so the installer's filename is kept.
    # Same symlink-into-store mechanism nix-darwin uses for its own
    # /etc/sudoers.d/10-nix-darwin-extra-config.
    environment.etc."sudoers.d/amphetamine_PowerProtect".text = ''
      Cmnd_Alias PMSET_AMPHETAMINE= /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0
      %admin ALL=(ALL) NOPASSWD: PMSET_AMPHETAMINE
    '';

    home-manager.sharedModules = [
      (
        { lib, ... }:
        {
          # Amphetamine runs the script sandboxed via NSUserAppleScriptTask,
          # which wants a real compiled .scpt inside its Application Scripts
          # dir rather than a symlink into the store, so compile it in place
          # at activation time (osacompile is idempotent and fast).
          home.activation.amphetaminePowerProtect = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run /bin/mkdir -p "$HOME/Library/Application Scripts/com.if.Amphetamine"
            run /usr/bin/osacompile -o "$HOME/Library/Application Scripts/com.if.Amphetamine/powerProtect.scpt" \
              ${./_powerProtect.applescript}
          '';
        }
      )
    ];
  };
}
