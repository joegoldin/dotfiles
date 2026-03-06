# NixOS module for the YepAnywhere relay server
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.yepanywhere-relay;
in
{
  options.services.yepanywhere-relay = {
    enable = lib.mkEnableOption "YepAnywhere relay server";

    package = lib.mkPackageOption pkgs "yepanywhere-relay" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4400;
      description = "Port for the relay server to listen on.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "yepanywhere-relay";
      description = "User account under which the relay runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "yepanywhere-relay";
      description = "Group under which the relay runs.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/yepanywhere-relay";
      description = "Directory for relay data (SQLite database, logs).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the relay.";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [
        "trace"
        "debug"
        "info"
        "warn"
        "error"
        "fatal"
      ];
      default = "info";
      description = "Log level for the relay server.";
    };

    reclaimDays = lib.mkOption {
      type = lib.types.int;
      default = 90;
      description = "Days of inactivity before a username can be reclaimed.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional environment variables for the relay service.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = lib.mkIf (cfg.user == "yepanywhere-relay") {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };

    users.groups.${cfg.group} = lib.mkIf (cfg.group == "yepanywhere-relay") { };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.yepanywhere-relay = {
      description = "YepAnywhere Relay Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        NODE_ENV = "production";
        RELAY_PORT = toString cfg.port;
        RELAY_DATA_DIR = cfg.dataDir;
        RELAY_LOG_LEVEL = cfg.logLevel;
        RELAY_RECLAIM_DAYS = toString cfg.reclaimDays;
        RELAY_LOG_TO_FILE = "true";
      }
      // cfg.environment;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/yepanywhere-relay";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
