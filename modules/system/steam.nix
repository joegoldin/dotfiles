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

  den.aspects.steam.homeManager =
    { pkgs, ... }:
    {
      xdg.desktopEntries.vortex-nxm = {
        name = "Vortex (Nexus Mod Manager)";
        # Browser launches do not inherit Steam's FHS environment.
        exec = "${pkgs.steam-run}/bin/steam-run ${pkgs.steamtinkerlaunch}/bin/steamtinkerlaunch vortex u %u";
        terminal = false;
        noDisplay = true;
        mimeType = [
          "x-scheme-handler/nxm"
          "x-scheme-handler/nxm-protocol"
        ];
      };
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/nxm" = "vortex-nxm.desktop";
          "x-scheme-handler/nxm-protocol" = "vortex-nxm.desktop";
        };
      };
    };
}
