{
  config,
  pkgs,
  dotfiles-secrets,
  ...
}:
let
  mountsCfg = import "${dotfiles-secrets}/mounts.nix";

  smbOpts = [
    "credentials=${config.age.secrets.smb-credentials.path}"
    "uid=1000"
    "gid=100"
    "nofail"
    "noauto"
    "_netdev"
    "x-systemd.device-timeout=5s"
    "x-systemd.mount-timeout=5s"
  ];

  mkMount = share: {
    name = share.mountPoint;
    value = {
      device = "${mountsCfg.serverAddress}/${share.name}";
      fsType = "cifs";
      options = smbOpts;
    };
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

  fileSystems = builtins.listToAttrs (map mkMount mountsCfg.shares);
  systemd.automounts = map mkAutomount mountsCfg.shares;
}
