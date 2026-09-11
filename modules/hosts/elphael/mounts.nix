{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.elphael.nixos =
    {
      config,
      pkgs,
      ...
    }:
    let
      mountsCfg = import "${dotfiles-secrets}/mounts.nix";

      smbOpts = [
        "credentials=${config.age.secrets.smb-credentials.path}"
        "uid=1000"
        "gid=100"
        "_netdev"
      ];

      # A plain systemd.mounts entry rather than fileSystems: the fstab
      # generator cannot set StartLimit*, and without it every access while
      # the server is unreachable blocks the caller for the full mount
      # timeout, over and over. With the limit, systemd refuses further
      # attempts for a minute after two failures and callers get an
      # immediate error instead of a hung desktop.
      mkMount = share: {
        what = "${mountsCfg.serverAddress}/${share.name}";
        where = share.mountPoint;
        type = "cifs";
        options = builtins.concatStringsSep "," smbOpts;
        unitConfig = {
          StartLimitIntervalSec = "60";
          StartLimitBurst = "2";
        };
        mountConfig.TimeoutSec = "5s";
      };

      mkAutomount = share: {
        where = share.mountPoint;
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
      };
    in
    {
      environment.systemPackages = [ pkgs.cifs-utils ];

      age.secrets.smb-credentials = {
        file = "${dotfiles-secrets}/smb-credentials.age";
        mode = "0400";
        owner = "root";
      };

      systemd.mounts = map mkMount mountsCfg.shares;
      systemd.automounts = map mkAutomount mountsCfg.shares;
    };
}
