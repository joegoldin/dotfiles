{
  dotfiles-secrets,
  username,
  ...
}:
let
  drivesCfg = import "${dotfiles-secrets}/data-drives.nix";

  mkLuksDevice = drive: {
    name = drive.luksName;
    value = {
      device = "/dev/disk/by-uuid/${drive.uuid}";
      keyFile = "/etc/secrets/luks-data.key";
      fallbackToPassword = true;
    };
  };

  mkFileSystem = drive: {
    name = drive.mountPoint;
    value = {
      device = "/dev/mapper/${drive.luksName}";
      fsType = "ext4";
    };
  };

  mkTmpfilesRule = drive: "d ${drive.mountPoint} 0755 ${username} users -";
in
{
  boot.initrd.secrets."/etc/secrets/luks-data.key" = "/etc/secrets/luks-data.key";
  boot.initrd.luks.devices = builtins.listToAttrs (map mkLuksDevice drivesCfg);
  fileSystems = builtins.listToAttrs (map mkFileSystem drivesCfg);
  systemd.tmpfiles.rules = map mkTmpfilesRule drivesCfg;
}
