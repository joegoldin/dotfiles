# Lightweight home-manager config for the headless siofra server: the
# shared server-cli aspect (modules/home/server-cli.nix) instead of the
# full home-baseline.
{ den, ... }:
{
  den.aspects.siofra.includes = [ den.aspects.server-cli ];
}
