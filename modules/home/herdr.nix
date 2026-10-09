# One local session server per user; remote clients reach it through SSH.
{ inputs, den, ... }:
let
  meta = import ../_lib/meta.nix;
in
{
  perSystem =
    { system, pkgs, ... }:
    {
      packages = (import ./_herdr/packages.nix { inherit inputs pkgs; }) // {
        herdr = inputs.herdr.packages.${system}.default;
      };
    };

  den.aspects.herdr = {
    includes = [ den.aspects.herdr-addons ];
    # Start at boot and retain sessions after the last SSH logout.
    provides.to-hosts.nixos.users.users.${meta.username}.linger = true;

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        package = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
        environment = {
          HOME = config.home.homeDirectory;
          SHELL = "${pkgs.fish}/bin/fish";
          XDG_CONFIG_HOME = config.xdg.configHome;
          XDG_STATE_HOME = config.xdg.stateHome;
          PATH = lib.concatStringsSep ":" [
            "${config.home.profileDirectory}/bin"
            "/etc/profiles/per-user/${config.home.username}/bin"
            "/run/current-system/sw/bin"
            (lib.makeBinPath [
              pkgs.curl
              pkgs.git
              pkgs.openssh
            ])
            "/usr/bin"
            "/bin"
            "/usr/sbin"
            "/sbin"
          ];
        };
      in
      {
        home.packages = [ package ];

        # Release checks and agent-detection downloads retain upstream defaults.
        systemd.user.services.herdr = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          Unit.Description = "Herdr persistent terminal sessions";
          Service = {
            ExecStart = "${package}/bin/herdr server";
            WorkingDirectory = config.home.homeDirectory;
            Environment = lib.mapAttrsToList (name: value: "${name}=${value}") environment;
            Restart = "on-failure";
            RestartSec = 5;
            UMask = "0077";
          };
          Install.WantedBy = [ "default.target" ];
        };

        launchd.agents.herdr = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.python3}/bin/python3"
              "${./_herdr/launchd.py}"
              "${package}/bin/herdr"
              "server"
            ];
            WorkingDirectory = config.home.homeDirectory;
            EnvironmentVariables = environment;
            KeepAlive = {
              SuccessfulExit = false;
            };
            RunAtLoad = true;
            ProcessType = "Background";
            ThrottleInterval = 5;
            Umask = 63;
          };
        };
      };
  };
}
