# modules/system/_sys/gaming.nix
# Steam, GameMode, Lutris, and gaming performance tools
{ ... }:
let
  meta = import ../_lib/meta.nix;
  username = meta.username;
in
{
  den.aspects.gaming.nixos =
    {
      pkgs,
      ...
    }:
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        extraPackages = with pkgs; [
          mangohud
        ];
      };

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
        # wowup-cf  # disabled: upstream download fails with TLS handshake error
        unstable.vintagestory
      ];

      users.users."${username}".extraGroups = [ "gamemode" ];
    };
}
