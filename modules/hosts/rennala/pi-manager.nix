# Dispatch-disabled acceptance deployment; native Pi and SSH remain host-managed.
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.rennala.includes = [ den.aspects.pi-manager ];
  den.aspects.rennala.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = meta.username;
      home = config.users.users.${user}.home;
      runtime = "/run/user/1000/pi-manager";
      credentials = "${runtime}/credentials";
      application = config.services.pi-manager.controller.package;
      grant = {
        allowedOperations = [
          "state.get"
          "jobs.list"
          "jobs.get"
          "schedules.list"
          "schedules.get"
          "schedules.preview"
        ];
        allowedWorkspaces = [ "manager" ];
        allowedProfiles = [
          "cli"
          "desktop"
        ];
        allowedResources = [
          "cli"
          "desktop"
        ];
        approvedTemplateHashes = [ ];
        jobSubmissionPolicy = "configured_limits";
        maximumMutations = 8;
      };
      # The owner allowlist is injected from an owned agenix credential at runtime.
      template = (pkgs.formats.json { }).generate "pi-manager-controller-template.json" {
        version = 1;
        core = {
          version = 1;
          principal = "you";
          stateDirectory = "${home}/.local/state/pi-manager";
          runtimeDirectory = runtime;
          sessionDirectory = "${home}/.local/state/pi-manager/sessions";
          resultDirectory = "${home}/.local/state/pi-manager/results";
          encryptionKeyFile = "${credentials}/native-key";
          admission = {
            workspaceRoot = "${home}/pi-manager-workspaces";
            workspaces.manager = "manager";
            profiles = {
              cli.resources = [ "cli" ];
              desktop.resources = [ "desktop" ];
            };
            maxima = {
              workTokenBudget = 100000;
              maxActiveSeconds = 120;
              maxElapsedSeconds = 120;
              queuedJobs = 8;
            };
          };
          execution = {
            systemdRun = "${pkgs.systemd}/bin/systemd-run";
            systemctl = "${pkgs.systemd}/bin/systemctl";
            flock = "${pkgs.util-linux}/bin/flock";
            scopeLauncher = "${application}/lib/pi-manager-agent/dist/cli/exec-pi.js";
            memoryMaxBytes = 805306368;
            tasksMax = 128;
            cpuQuotaPercent = 50;
          };
          pi = {
            executable = "/etc/profiles/per-user/${user}/bin/pi";
            version = "1.4.0";
            homeDirectory = home;
            searchPath = [
              "/etc/profiles/per-user/${user}/bin"
              "/run/current-system/sw/bin"
            ];
            xdgConfigHome = "${home}/.config";
            xdgCacheHome = "${home}/.cache";
            xdgDataHome = "${home}/.local/share";
            xdgRuntimeDirectory = "/run/user/1000";
          };
          limits = {
            active = 1;
            resident = 1;
          };
          worker = {
            maxFinalizationSeconds = 20;
            wrapUpTokenAllowance = 1024;
            inputTimeoutSeconds = 60;
            maxModelTurns = 50;
            inherit grant;
          };
          supervisor = {
            workspace = "manager";
            profile = "cli";
            workTokenBudget = 100000;
            maxActiveSeconds = 120;
            maxElapsedSeconds = 120;
            sources.pwa = {
              kind = "pwa";
              revision = 1;
              inherit grant;
            };
          };
          dispatchEnabled = false;
        };
        browser = {
          identity = {
            issuer = "https://auth.turnin.quest/";
            sourceId = "pwa";
            sessionKeyFile = "${credentials}/session-key";
          };
          listener = {
            publicOrigin = "https://display.amia.live";
            clientId = "pi-manager-agent";
            clientSecretFile = "${credentials}/oidc-secret";
            mfaAcrValues = [ ];
            listen = {
              host = "127.0.0.1";
              port = 8787;
            };
          };
        };
        desktop = config.services.pi-manager.desktop.applicationConfig;
        webhooks = { };
      };
      secretNames = [
        "pi-manager-authhero-client-secret"
        "pi-manager-native-key"
        "pi-manager-session-key"
        "pi-manager-browser-policy.json"
        "pi-manager-desktop-json-key"
        "pi-manager-desktop-vnc-password"
      ];
    in
    {
      system.build.pi-manager-controller-template = template;
      users.users.${user}.uid = 1000;
      age.secrets = lib.genAttrs secretNames (name: {
        file = "${inputs.dotfiles-secrets}/${name}.age";
        owner = user;
        group = "users";
        mode = "0400";
      });
      services = {
        pi-manager = {
          controller = {
            enable = true;
            inherit user;
            mode = "desktop";
            configurationFile = "${runtime}/controller.json";
            credentials = {
              native-key = config.age.secrets.pi-manager-native-key.path;
              session-key = config.age.secrets.pi-manager-session-key.path;
              oidc-secret = config.age.secrets.pi-manager-authhero-client-secret.path;
              browser-policy = config.age.secrets."pi-manager-browser-policy.json".path;
            };
          };
          desktop = {
            enable = true;
            jsonKeyFile = config.age.secrets.pi-manager-desktop-json-key.path;
            vncPasswordFile = config.age.secrets.pi-manager-desktop-vnc-password.path;
          };
        };
        caddy = {
          enable = true;
          virtualHosts."display.amia.live" = {
            # Callback query parameters and authenticated desktop URLs are not access logs.
            logFormat = "output discard";
            extraConfig = ''
              reverse_proxy 127.0.0.1:8787 {
                header_up Host display.amia.live
                header_up -X-Forwarded-For
                header_up -X-Forwarded-Proto
                header_up -X-Forwarded-Host
              }
            '';
          };
        };
      };
      systemd = {
        tmpfiles.rules = [
          "d ${home}/pi-manager-workspaces 0700 ${user} users -"
          "d ${home}/pi-manager-workspaces/manager 0700 ${user} users -"
        ];
        user.services.pi-manager-controller.serviceConfig = {
          ExecStartPre = lib.mkAfter [
            (lib.escapeShellArgs [
              "${pkgs.nodejs_24}/bin/node"
              "${./_render-pi-manager.mjs}"
              "${application}"
              "${template}"
              "${credentials}/browser-policy"
              "${runtime}/controller.json"
            ])
          ];
          MemoryMax = "384M";
          TasksMax = 128;
          CPUQuota = "50%";
        };
        services = {
          pi-manager-guacamole.serviceConfig.MemoryMax = "512M";
          pi-manager-guacd.serviceConfig.MemoryMax = "128M";
        };
      };
      # Only the maintained TLS frontend is public; SSH remains allowed in machine.nix.
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      assertions = [
        {
          assertion = config.home-manager.users.${user}.programs.pi.coding-agent.enable;
          message = "Rennala Pi Manager requires the normal Nix-managed Pi profile.";
        }
      ];
    };
}
