# common/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic.nix
    ../common/system/attic-post-build-hook.nix
    ../common/system/howdy.nix
    ./configuration.nix
    ./hardware-configuration.nix
    ./drag-shift.nix
    ./double-tap-overview.nix
    ../common/system/app-autostart.nix
    ../common/system/gaming.nix
    ./joe-desktop.nix
    ./wallpaper.nix
    ./mounts.nix
    ./uxplay.nix
    # ./hyprwhspr.nix
    ./yepanywhere.nix
    ./desk-phone.nix
    ./vban-send.nix
    # ./data-drives.nix
  ];
}
