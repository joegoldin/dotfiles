# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ lib, ... }:
{
  imports = [
    ../common/home
  ];

  # Disable desktop packages for headless server
  xdg.dataFile."fish-ai".enable = lib.mkForce false;
  home.activation.fishAiCleanup = lib.mkForce (lib.hm.dag.entryAnywhere "");

  services = {
    # lorri for nix-shell
    lorri.enable = true;

    gnome-keyring.enable = true;
  };
}
