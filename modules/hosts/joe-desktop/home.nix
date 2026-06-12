# Host-specific home config that isn't plasma (see ./plasma.nix for that):
# flatpaks, android tooling, desktop packages, python extras, dolphin places.
{ inputs, ... }:
{
  den.aspects.joe-desktop.homeManager = {
    imports = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ./_android.nix
      ./_packages
      ./_python.nix
      ./_dolphin.nix
    ];

    # TODO: git signing with 1password
    # programs.git = {
    #   enable = true;
    #   extraConfig = {
    #     gpg = {
    #       format = "ssh";
    #     };
    #     gpg."ssh" = {
    #       program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
    #     };
    #     commit = {
    #       gpgsign = true;
    #     };

    #     # user = {
    #     #   signingKey = "...";
    #     # };
    #   };
    # };
  };
}
