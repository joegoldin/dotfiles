{
  den.aspects.erdtree.nixos =
    { config, pkgs, ... }:
    let
      name = "erdtree-stall-recorder";
      pg = config.services.postgresql;
    in
    {
      users.groups.${name} = { };
      users.users.${name} = {
        isSystemUser = true;
        group = name;
      };
      # Local peer auth: SELECT 1 needs a login, not access to any Garnix tables.
      services.postgresql.ensureUsers = [ { inherit name; } ];
      systemd.services.${name} = {
        description = "Record eight days of Erdtree storage stalls and PostgreSQL latency";
        wantedBy = [ "multi-user.target" ];
        after = [ "postgresql.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.python3}/bin/python3 ${./_stall-recorder/recorder.py} ${pg.package}/bin/psql -X -w -qAt -h /run/postgresql -p ${toString pg.settings.port} -d postgres -c 'SELECT 1'";
          User = name;
          StateDirectory = name;
          StateDirectoryMode = "0700";
          UMask = "0077";
          Restart = "on-failure";
          RestartSec = "10s";
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectControlGroups = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
          RestrictAddressFamilies = [ "AF_UNIX" ];
        };
      };
    };
}
