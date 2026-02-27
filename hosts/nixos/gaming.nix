# hosts/nixos/gaming.nix
# Steam, GameMode, Lutris, and gaming performance tools
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

  environment.systemPackages = with pkgs; [
    (unstable.lutris.override {
      extraPkgs = pkgs: [
        # Additional packages for game installers/runners
      ];
      extraLibraries = pkgs: [
        # Additional libraries for game compatibility
      ];
    })
    adwaita-icon-theme
    wowup-cf
  ];

  users.users."${username}".extraGroups = [ "gamemode" ];
}
