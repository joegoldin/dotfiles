# Lightweight home-manager config for the headless erdtree server: the
# shared server-cli aspect (modules/home/server-cli.nix) instead of the
# full home-baseline.
{ den, ... }:
{
  den.aspects.erdtree.includes = [ den.aspects.server-cli ];
}
