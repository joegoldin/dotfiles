# Lightweight home-manager config for the headless rennala server: the
# shared server-cli aspect (modules/home/server-cli.nix) instead of the
# full home-baseline.
{ den, ... }:
{
  den.aspects.rennala.includes = [ den.aspects.server-cli ];
}
