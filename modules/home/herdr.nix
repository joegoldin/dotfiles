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
            "/run/wrappers/bin"
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

        # The package ships no completions; generate them from the binary.
        xdg.configFile."fish/completions/herdr.fish".source =
          pkgs.runCommand "herdr-fish-completions" { }
            ''
              HOME=$TMPDIR ${package}/bin/herdr completion fish > $out
            '';

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

        # Store paths live behind a stable link so the plist never changes:
        # activation boots out a changed agent, which kills every pane,
        # including one running the rebuild. New builds apply on restart.
        xdg.dataFile."herdr/launchd-server" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          source = pkgs.writeShellScript "herdr-launchd-server" ''
            ${lib.concatLines (
              lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") environment
            )}
            exec ${pkgs.python3}/bin/python3 ${./_herdr/launchd.py} ${package}/bin/herdr server
          '';
        };

        launchd.agents.herdr = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          enable = true;
          config = {
            ProgramArguments = [ "${config.xdg.dataHome}/herdr/launchd-server" ];
            WorkingDirectory = config.home.homeDirectory;
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
