# MIGRATED to the dendritic tree: the real module now lives in
# modules/home/_hm/git.nix and is exposed to den-managed hosts as
# `den.aspects.git`. This shim keeps not-yet-migrated hosts working
# unchanged; delete it once nothing under hosts/ imports it anymore.
{ ... }:
{
  imports = [ ../../../modules/home/_hm/git.nix ];
}
