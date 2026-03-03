# common/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic.nix
    ../common/system/attic-post-build-hook.nix
    ./configuration.nix
    ./hardware-configuration.nix
    ./drag-shift.nix
    ./gaming.nix
    ./joe-desktop.nix
    ./wallpaper.nix
    ./app-autostart.nix
  ];
}
