# User script library (~50 wrapped shell scripts + the `vm` CLI suite).
# The hm module stays a standalone file (./_module.nix) because microVM
# guests import it directly at runtime (see modules/_data/microvm/
# fish-guest.nix and common-guest.nix); outside den entirely.
{ ... }:
{
  den.aspects.bin.homeManager = ./_module.nix;
}
