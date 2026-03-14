# common/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic.nix
    ../common/system/attic-post-build-hook.nix
    ./configuration.nix
    ./hardware-configuration.nix
    ./drag-shift.nix
    ./double-tap-overview.nix
    ./gaming.nix
    ./joe-desktop.nix
    ./wallpaper.nix
    ./app-autostart.nix
    ./mounts.nix
    ./uxplay.nix
    ./yepanywhere.nix
    # ./data-drives.nix
  ];
}
