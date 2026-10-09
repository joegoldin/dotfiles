# Optional plugin bundle composed by the Herdr aspect.
{ inputs, ... }:
{
  den.aspects.herdr-addons.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      package = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
      addons = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
      plugins = with addons; [
        herdr-memex-plugin
        herdr-auto-title-plugin
        herdr-navigator-plugin
        herdr-ttt-plugin
      ];
      python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
      settings = pkgs.writeText "herdr-settings.json" (
        builtins.toJSON (import ./_herdr/settings.nix { inherit config; })
      );
    in
    {
      home.packages = [
        addons.memex
        addons.ttt
        addons.herdr-auto-title
        addons.herdr-navigator
      ];

      # Merge only owned settings; in particular, never change pane history.
      # Use Herdr's mutable registry so user-installed plugins remain intact.
      home.activation.configureHerdr = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
        run ${python}/bin/python3 ${./_herdr/configure.py} ${settings}
        ${lib.concatMapStringsSep "\n" (plugin: ''
          run ${pkgs.coreutils}/bin/env -u HERDR_SOCKET_PATH \
            XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome} \
            XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} \
            ${package}/bin/herdr plugin link ${plugin}
        '') plugins}
      '';

    };
}
