# hosts/nixos/gaming.nix
# Steam, GameMode, and gaming performance tools
{
  pkgs,
  username,
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

  users.users."${username}".extraGroups = [ "gamemode" ];
}
