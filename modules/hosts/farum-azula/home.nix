# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ ... }:
{
  den.aspects.farum-azula.homeManager = _: {
    imports = [
    ];

    services = {
      # lorri for nix-shell
      lorri.enable = true;

      gnome-keyring.enable = true;
    };
  };
}
