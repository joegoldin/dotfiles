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
  jovian.devices.steamdeck.enable = true;
  jovian.hardware.has.amd.gpu = true;
  jovian.steam.enable = true;
  jovian.steam.desktopSession = "plasma";

  services.displayManager.sddm.settings.Autologin = {
    Session = "gamescope-wayland.desktop";
    User = username;
  };

  fonts.packages =
    let
      customFonts = import ../common/system/fonts { inherit pkgs lib dotfiles-assets; };
    in
    [ customFonts.berkeley-mono-nerd-font ];
}
