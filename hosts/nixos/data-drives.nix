{
  dotfiles-secrets,
  username,
  ...
}:
let
  drivesCfg = import "${dotfiles-secrets}/data-drives.nix";

  # Use systemd-cryptsetup instead of initrd for non-root LUKS devices
  # This allows boot to continue without waiting for these drives
  mkCryptTab = drive:
    "${drive.luksName} /dev/disk/by-uuid/${drive.uuid} /etc/secrets/luks-data.key nofail,x-systemd.device-timeout=10s";

  mkFileSystem = drive: {
    name = drive.mountPoint;
    value = {
      device = "/dev/mapper/${drive.luksName}";
      fsType = "ext4";
      options = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=10s"
      ];
    };
  };

  mkTmpfilesRule = drive: "d ${drive.mountPoint} 0755 ${username} users -";
in
{
  environment.etc.crypttab = {
    mode = "0600";
    text = builtins.concatStringsSep "\n" (map mkCryptTab drivesCfg);
  };
  fileSystems = builtins.listToAttrs (map mkFileSystem drivesCfg);
  systemd.tmpfiles.rules = map mkTmpfilesRule drivesCfg;
}
