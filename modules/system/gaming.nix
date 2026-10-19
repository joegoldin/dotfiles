# modules/system/_sys/gaming.nix
# Steam, GameMode, Lutris, and gaming performance tools
{ den, ... }:
let
  meta = import ../_lib/meta.nix;
  username = meta.username;
in
{
  den.aspects.gaming.includes = [ den.aspects.steam ];

  den.aspects.gaming.nixos =
    {
      pkgs,
      ...
    }:
    {
      programs.gamemode = {
        enable = true;
        settings.general.inhibit_screensaver = 0;
      };

      environment.systemPackages = with pkgs; [
        (unstable.lutris.override {
          extraPkgs = pkgs: [ ];
          extraLibraries = pkgs: [ ];
        })
        adwaita-icon-theme
        unstable.cockatrice
        unstable.rusty-path-of-building
        # wowup-cf  # disabled: upstream download fails with TLS handshake error
        unstable.vintagestory
        unstable.gale
      ];

      users.users."${username}".extraGroups = [ "gamemode" ];
    };
}
