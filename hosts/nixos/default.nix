# common/default.nix
{ ... }:
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./drag-shift.nix
    ./gaming.nix
    ./joe-desktop.nix
    ./wallpaper.nix
  ];
}
