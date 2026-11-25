# Upload new store paths independently of the Nix build scheduler.
{ inputs, ... }:
let
  caches = import ../_lib/ci-caches.nix inputs;
  attic = import "${inputs.dotfiles-secrets}/attic.nix";
in
{
  den.aspects.celler-watch-store = {
    nixos =
      { config, pkgs, ... }:
      let
        celler = inputs.celler.packages.${pkgs.stdenv.hostPlatform.system}.celler;
      in
      {
        systemd.services.celler-watch-store = {
          description = "Upload new Nix store paths to Celler";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "agenix.service"
            "nix-daemon.socket"
          ];
          unitConfig.StartLimitIntervalSec = 0;
          serviceConfig = {
            DynamicUser = true;
            LoadCredential = "celler-token:${config.age.secrets.attic-token.path}";
            RuntimeDirectory = "celler-watch-store";
            Environment = "XDG_CONFIG_HOME=/run/celler-watch-store";
            Restart = "always";
            RestartSec = 30;
            UMask = "0077";
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
          };
          # Only the credential path is written to the config, never its contents.
          script = ''
            mkdir -p "$XDG_CONFIG_HOME/celler"
            cat > "$XDG_CONFIG_HOME/celler/config.toml" <<EOF
            [servers.default-server]
            endpoint = "${caches.cellerURL}/"
            token-file = "$CREDENTIALS_DIRECTORY/celler-token"
            EOF
            exec ${celler}/bin/celler watch-store --jobs 5 default-server:${attic.cacheName}
          '';
        };
      };

    darwin =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        celler = inputs.celler.packages.${pkgs.stdenv.hostPlatform.system}.celler;
        tokenFile = config.age.secrets.attic-token.path;
      in
      {
        launchd.daemons.celler-watch-store = {
          environment.XDG_CONFIG_HOME = "/var/run/celler-watch-store";
          path = [
            pkgs.coreutils
            config.nix.package
          ];
          serviceConfig = {
            RunAtLoad = true;
            KeepAlive = true;
            ThrottleInterval = 30;
            UserName = "root";
            Umask = 63;
            ProcessType = "Background";
            StandardOutPath = "/var/log/celler-watch-store.log";
            StandardErrorPath = "/var/log/celler-watch-store.log";
          };
          # launchd cannot order this after agenix or network startup. A failed
          # prerequisite exits so KeepAlive retries without blocking activation.
          script = ''
            set -euo pipefail
            umask 077
            test -r ${lib.escapeShellArg tokenFile}
            mkdir -p "$XDG_CONFIG_HOME/celler"
            chmod 0700 "$XDG_CONFIG_HOME"
            cat > "$XDG_CONFIG_HOME/celler/config.toml" <<EOF
            [servers.default-server]
            endpoint = "${caches.cellerURL}/"
            token-file = "${tokenFile}"
            EOF
            exec ${celler}/bin/celler watch-store --jobs 5 default-server:${attic.cacheName}
          '';
        };
      };
  };
}
