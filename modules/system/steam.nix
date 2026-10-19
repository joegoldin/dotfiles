# Steam and its compatibility tools, shared by desktop and Jovian hosts.
{
  den.aspects.steam.nixos =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        extraPackages = with pkgs; [
          mangohud
          steamtinkerlaunch
        ];
        # Register declaratively; no mutable `steamtinkerlaunch compat add` needed.
        extraCompatPackages = [ pkgs.steamtinkerlaunch ];
      };

      environment.systemPackages = [ pkgs.steamtinkerlaunch ];
    };
}
