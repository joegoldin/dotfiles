# git + delta. Migration pattern A (fully moved): the home-manager module
# was moved from hosts/common/home/git.nix to ./_hm/git.nix (underscore =
# invisible to import-tree), and the legacy path is now a one-line shim
# importing it. Once no host under hosts/ imports the shim, inline _hm/git.nix
# here as a plain attrset/function and delete both indirections.
{ ... }:
{
  den.aspects.git.homeManager = ./_hm/git.nix;
}
