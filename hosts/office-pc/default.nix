# hosts/office-pc/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic.nix
    ../common/system/attic-post-build-hook.nix
    ./configuration.nix
    ./hardware-configuration.nix
    ./office-pc.nix
  ];
}
