_: {
  den.aspects.fish.homeManager =
    {
      pkgs,
      lib,
      ...
    }:
    {
      programs.fish = {
        enable = true;
        inherit ((import ./_init.nix { inherit pkgs; })) interactiveShellInit;
        functions = import ./_functions.nix;
        inherit ((import ./_plugins.nix { inherit pkgs; })) plugins;
        inherit ((import ./_aliases.nix { inherit lib pkgs; }))
          shellAbbrs
          shellAliases
          ;
      };

      # The grc.fish plugin (see _plugins.nix) shells out to `grc`; ship the
      # binary with the fish aspect so it's present on lean hosts too (otherwise
      # fish prints a "grc not found" warning on startup).
      home.packages = [ pkgs.grc ];
    };
}
