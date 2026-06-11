# gpg + gpg-agent. Migration pattern B (pointed-at).
{ ... }:
{
  den.aspects.gpg.homeManager = ../../hosts/common/home/gpg.nix;
}
