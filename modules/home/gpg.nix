# gpg + gpg-agent.
{ ... }:
{
  den.aspects.gpg.homeManager = ./_hm/gpg.nix;
}
