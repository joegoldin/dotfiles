# Collie: phone web UI for the agents running in herdr. Remote shell access
# by design, so the bridge stays on loopback and the only front door is
# `tailscale serve` (never funnel): HTTPS for the PWA, mic and web push, and
# the Tailscale-User-Login header COLLIE_TRUSTED_USER checks. Devices still
# need `collie pair`. Dictation runs audiomemo's local Parakeet per
# recording, so no model stays resident between uses.
#
# Runtime state outside the store: pairings in ~/.local/state/collie, and the
# VAPID keys `collie push-keys` writes (mode 600) to the .env in Herdr's
# plugin config dir, which the bridge, the CLI and the plugin's actions all
# read.
{ inputs, ... }:
let
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
  port = 8787;
  # Where Herdr points the plugin's actions; the service and the CLI follow.
  configDir = config: "${config.xdg.configHome}/herdr/plugins/config/herdr.collie";

  collieFor =
    pkgs:
    pkgs.callPackage ./_collie-package.nix {
      src = inputs.collie;
      # Keep upstream's exact Bun archive without importing its separate
      # bootstrap toolchain; our nixpkgs Bun is older than Collie's MIN_BUN.
      bun =
        let
          upstream = inputs.collie.packages.${pkgs.stdenv.hostPlatform.system}.bun;
        in
        pkgs.bun.overrideAttrs (_: {
          inherit (upstream) version;
          src = pkgs.fetchurl {
            inherit (upstream.src) url;
            hash = upstream.src.outputHash;
          };
        });
    };
in
{
  den.aspects.elphael.nixos =
    { config, ... }:
    {
      # The tailnet front door, owned here rather than by `collie start`.
      systemd.services.collie-tailscale-serve = {
        description = "Publish Collie on the tailnet via tailscale serve";
        after = [ "tailscaled.service" ];
        requires = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 http://127.0.0.1:${toString port}";
          ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 off";
        };
      };
    };

  den.aspects.elphael.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      collie = collieFor pkgs;
      herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
      manifest = builtins.fromTOML (builtins.readFile "${collie}/lib/collie/herdr-plugin.toml");
      # The upstream manifest's buttons, minus the lifecycle and update verbs:
      # home-manager owns the service and the flake lock owns the version.
      # Restart maps to the managed unit so push-keys can take effect.
      plugin = pkgs.runCommand "herdr-collie-plugin" { } ''
        mkdir -p $out
        cp ${
          (pkgs.formats.toml { }).generate "herdr-plugin.toml" (
            manifest
            // {
              build = [ ];
              actions =
                map
                  (
                    entry:
                    entry
                    // {
                      command =
                        if entry.id == "restart" then
                          [
                            "${pkgs.systemd}/bin/systemctl"
                            "--user"
                            "restart"
                            "collie.service"
                          ]
                        else
                          [
                            "${collie}/bin/collie"
                            entry.id
                          ];
                    }
                  )
                  (
                    builtins.filter (
                      entry:
                      builtins.elem entry.id [
                        "restart"
                        "url"
                        "status"
                        "version"
                        "push-keys"
                        "push-test"
                      ]
                    ) manifest.actions
                  );
            }
          )
        } $out/herdr-plugin.toml
        cp ${collie}/lib/collie/LICENSE $out/LICENSE
      '';
      # local-cli appends the recording's path as the last argument and reads
      # the transcript from stdout. That stdout is a socket, which
      # `-o /dev/stdout` cannot open, so the transcript is printed as usual;
      # its sidecar lands in Collie's temp dir and is deleted with it.
      transcribe = pkgs.writeShellScript "collie-transcribe" ''
        exec ${config.programs.audiomemo.package}/bin/audiomemo transcribe \
          -b nemo --diarize=false "$@"
      '';
    in
    {
      home.packages = [ collie ];
      # Keep the CLI (pair, devices, push-keys) on the bridge's config dir.
      home.sessionVariables.HERDR_PLUGIN_CONFIG_DIR = configDir config;

      # Same registry write as herdr-addons' plugins.
      home.activation.linkColliePlugin = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
        run ${pkgs.coreutils}/bin/env -u HERDR_SOCKET_PATH \
          XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome} \
          XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} \
          ${herdr}/bin/herdr plugin link ${plugin}
      '';

      systemd.user.services.collie = {
        Unit = {
          Description = "Collie";
          After = [ "herdr.service" ];
          # Never give up restarting; a phone-only operator can't reset-failed.
          StartLimitIntervalSec = 0;
        };
        Service = {
          ExecStart = "${collie}/bin/collie _exec-bridge";
          WorkingDirectory = "${collie}/lib/collie";
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          PrivateTmp = true;
          Environment = [
            "HERDR_SOCKET_PATH=${config.xdg.configHome}/herdr/herdr.sock"
            "HERDR_PLUGIN_CONFIG_DIR=${configDir config}"
            "COLLIE_PORT=${toString port}"
            "COLLIE_TAILSCALE_HOSTS=${domains.elphaelTailscale}"
            "COLLIE_TRUSTED_USER=${domains.tailscaleUser}"
            "COLLIE_AUDIT_CONTENT=none"
            "COLLIE_VAPID_SUBJECT=mailto:${domains.tailscaleUser}"
            "COLLIE_STT_PROVIDER=local-cli"
            "COLLIE_STT_COMMAND=${transcribe}"
          ];
          EnvironmentFile = "-${configDir config}/.env";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
