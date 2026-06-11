# GitHub CLI + extensions. Migration pattern B (pointed-at): the legacy
# module takes no specialArgs, so the aspect can reference it directly.
{ ... }:
{
  den.aspects.gh.homeManager = ../../hosts/common/home/gh.nix;
}
