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
        unstable.rusty-path-of-building
        # wowup-cf  # disabled: upstream download fails with TLS handshake error
        unstable.vintagestory
        # Gale hardcodes steam.sh before `steam` on PATH; the bare script cannot
        # run outside the FHS sandbox the wrapper provides.
        (unstable.gale.overrideAttrs (previousAttrs: {
          patches = (previousAttrs.patches or [ ]) ++ [ ./patches/gale-prefer-path-steam.patch ];
        }))
      ];

      users.users."${username}".extraGroups = [ "gamemode" ];
    };
}
