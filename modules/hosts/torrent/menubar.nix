_: {
  den.aspects.torrent.darwin =
    { config, lib, ... }:
    let
      layout = builtins.fromJSON (builtins.readFile ./_menubar-layout.json);
      user = lib.escapeShellArg config.system.primaryUser;
    in
    {
      # Keep the native menu bar ordering and visibility captured on this Mac.
      # Analytics and unrelated preferences are deliberately not included.
      system.defaults.CustomUserPreferences = layout.preferences;

      # Control Center stores its customized controls as plist data, not strings.
      # Write those keys individually so other preferences remain untouched.
      system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          domain: entries:
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              key: value:
              ''/bin/launchctl asuser "$(/usr/bin/id -u -- ${user})" /usr/bin/sudo --user=${user} -- /usr/bin/defaults write ${lib.escapeShellArg domain} ${lib.escapeShellArg key} -data ${lib.escapeShellArg value}''
            ) entries
          )
        ) layout.data
      );
    };
}
