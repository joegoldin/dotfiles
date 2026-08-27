# Userspace tooling for every filesystem GParted can drive, so its "Format to"
# menu isn't half greyed out and `mount` works on whatever gets plugged in.
#
# GParted greys an entry out when the matching mkfs/fsck binary isn't on PATH.
# Two ways to supply them:
#
#   boot.supportedFilesystems  — for the types NixOS has a module for. It adds
#     the tools to system.fsPackages (which lands in environment.systemPackages)
#     *and* wires the kernel side, so the filesystem also mounts.
#   environment.systemPackages — for the types with no NixOS module. mkfs works;
#     mounting still depends on the kernel carrying the driver (hfsplus, nilfs2
#     and udf are all in mainline, so in practice they do).
#
# ext2/3/4, fat16/32, linux-swap, lvm2 pv and minix need nothing here: e2fsprogs,
# dosfstools and util-linux are already in the default system closure.
{ ... }:
{
  den.aspects.filesystem-tools.nixos =
    { pkgs, ... }:
    {
      boot.supportedFilesystems = {
        btrfs = true;
        exfat = true; # exfatprogs on >= 5.7 kernels, not the dead exfat-utils
        f2fs = true;
        jfs = true;
        ntfs = true;
        xfs = true;
      };

      environment.systemPackages = with pkgs; [
        # bcachefs deliberately stays out of boot.supportedFilesystems: that
        # option unconditionally adds the out-of-tree module package, which
        # means a kernel-module compile on every kernel bump. The tools alone
        # give GParted mkfs.bcachefs; mounting needs the module, which the
        # mainline kernel still provides.
        bcachefs-tools
        hfsprogs # mkfs.hfsplus / fsck.hfsplus
        hfsutils # hformat, for plain HFS — hfsprogs only does HFS+
        nilfs-utils
        udftools
      ];

      # reiserfs and reiser4 stay unavailable: reiserfsprogs was dropped from
      # nixpkgs (unmaintained upstream) and reiser4progs is marked broken.
    };
}
