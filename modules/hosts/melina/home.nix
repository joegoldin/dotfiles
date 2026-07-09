# Lightweight home-manager config for the headless melina server: the
# shared server-cli aspect (modules/home/server-cli.nix) instead of the
# full home-baseline.
{ den, ... }:
{
  den.aspects.melina.includes = [ den.aspects.server-cli ];
}
