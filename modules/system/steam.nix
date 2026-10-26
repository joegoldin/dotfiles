# Steam and its compatibility tools, shared by desktop and Jovian hosts.
{
  den.aspects.steam.nixos =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        package = pkgs.steam.override {
          # Windows .NET helpers must not resolve the host's Linux SDK.
          extraProfile = ''
            unset DOTNET_ROOT DOTNET_ROOT_X64 DOTNET_ROOT_X86 'DOTNET_ROOT(x86)'
          '';
        };
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
    let
      vortex-nxm = pkgs.writeShellApplication {
        name = "vortex-nxm";
        runtimeInputs = [ pkgs.libnotify ];
        # Reuse the running prefix's namespace: a fresh steam-run isolates Wine IPC.
        text = ''
          exec ${pkgs.python3}/bin/python3 ${./_steam/vortex_nxm.py} ${pkgs.util-linux}/bin/nsenter "$@"
        '';
      };
    in
    {
      xdg.desktopEntries.vortex-nxm = {
        name = "Vortex (Nexus Mod Manager)";
        exec = "${vortex-nxm}/bin/vortex-nxm %u";
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
