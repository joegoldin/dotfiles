# day-sync (agent-skills skill): render its private config from
# dotfiles-secrets; `force` supersedes any hand-written file. Rides on
# workstation-packages, so it reaches the mac + linux workstations; the
# kanary notion token it reads at runtime is wired per-host (torrent).
{ inputs, ... }:
let
  daySync = import "${inputs.dotfiles-secrets}/day-sync.nix";
in
{
  den.aspects.day-sync.homeManager =
    { config, ... }:
    {
      xdg.configFile."day-sync/config.json" = {
        force = true;
        text = builtins.toJSON (
          {
            vault = "${config.home.homeDirectory}/${daySync.vaultRelative}";
          }
          // removeAttrs daySync [ "vaultRelative" ]
        );
      };
    };
}
