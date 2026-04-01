{
  dotfiles-secrets,
  username,
  pkgs,
  ...
}:
let
  drives = import "${dotfiles-secrets}/data-drives.nix";

  # Post-boot LUKS unlock via crypttab with keyfile, nofail so boot isn't blocked
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

  # Convert mount point to systemd unit name (e.g. /mnt/data1 -> mnt-data1)
  mountToUnit = mp: builtins.replaceStrings [ "/" ] [ "-" ] (builtins.substring 1 (builtins.stringLength mp - 1) mp);

  mkChownService = drive: {
    name = "fix-ownership-${mountToUnit drive.mountPoint}";
    value = {
      description = "Fix ownership of ${drive.mountPoint}";
      after = [ "${mountToUnit drive.mountPoint}.mount" ];
      requires = [ "${mountToUnit drive.mountPoint}.mount" ];
      wantedBy = [ "${mountToUnit drive.mountPoint}.mount" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/chown ${username}:users ${drive.mountPoint}";
        ExecStartPost = "${pkgs.coreutils}/bin/chmod 0755 ${drive.mountPoint}";
      };
    };
  };
in
{
  environment.etc.crypttab = {
    mode = "0600";
    text = builtins.concatStringsSep "\n" (map mkCryptTab drives);
  };
  fileSystems = builtins.listToAttrs (map mkFileSystem drives);
  systemd.tmpfiles.rules = map mkTmpfilesRule drives;
  systemd.services = builtins.listToAttrs (map mkChownService drives);
}
