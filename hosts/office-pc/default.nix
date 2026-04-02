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
    ./disk-config.nix
    ./hardware-configuration.nix
    ../common/system/drag-shift.nix
    ./office-pc.nix
  ];
}
