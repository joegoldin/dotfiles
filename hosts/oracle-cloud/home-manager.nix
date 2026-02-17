# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  pkgs,
  ...
}:
{
  imports = [
    ../common/home
  ];

  programs.gpg.enable = true;

  services = {
    # lorri for nix-shell
    lorri.enable = true;

    # gnupg gpg stuff
    gnome-keyring.enable = true;
    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-curses;
    };
  };
}
