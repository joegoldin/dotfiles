# hosts/office-pc/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic.nix
    ../common/system/attic-post-build-hook.nix
    ../common/system/app-autostart.nix
    ../common/system/gaming.nix
    ../common/system/howdy.nix
    ./configuration.nix
    ./hardware-configuration.nix
    ./office-pc.nix
  ];
}
