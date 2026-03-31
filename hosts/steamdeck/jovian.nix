# hosts/steamdeck/jovian.nix
# Jovian NixOS: Steam Deck hardware, Game Mode, desktop switching
{
  pkgs,
  lib,
  username,
  dotfiles-assets,
  ...
}:
{
  jovian = {
    # Steam Deck hardware support (display, controls, fan, etc.)
    devices.steamdeck.enable = true;

    # AMD GPU support
    hardware.has.amd.gpu = true;

    # Steam + gamescope session (Game Mode)
    steam.enable = true;

    # KDE Plasma as the desktop session — enables "Return to Gaming Mode" shortcut
    steam.desktopSession = "plasma";
  };

  # Auto-login to Game Mode via SDDM
  services.displayManager.sddm.settings.Autologin = {
    Session = "gamescope-wayland.desktop";
    User = username;
  };

  # Fonts
  fonts.packages =
    let
      customFonts = import ../common/system/fonts { inherit pkgs lib dotfiles-assets; };
    in
    [ customFonts.berkeley-mono-nerd-font ];
}
