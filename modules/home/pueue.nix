# pueue (https://github.com/Nukesor/pueue): queue long-running shell commands
# and manage them from anywhere. The bare package alone errors with "Couldn't
# find a configuration file" — services.pueue writes pueue.yml and runs pueued
# as a systemd user service (launchd agent on darwin). Included via
# cli-packages, so every box gets a working daemon.
_: {
  den.aspects.pueue.homeManager = _: {
    services.pueue = {
      enable = true;
      # Defaults are sensible (1 parallel task, unix socket); add overrides
      # here as settings.daemon.* / settings.client.* when needed.
      settings = { };
    };
  };
}
