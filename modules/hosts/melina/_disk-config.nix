# LUKS-encrypted root, unlocked remotely over SSH in the initrd (see machine.nix).
# Mini PC: single 954 GB NVMe, UEFI. GPT: 1G ESP (/boot — systemd-boot + kernel +
# initrd, unencrypted so the initrd can unlock LUKS) + the LUKS container filling
# the rest. Swap is a 16 GiB swapfile on the encrypted root (machine.nix).
# Passphrase set at install via nixos-anywhere --disk-encryption-keys; typed over
# the initrd SSH session on every boot. disko ERASES /dev/nvme0n1.
#
# NOTE: encrypted means the box does NOT auto-boot after a power loss — Home
# Assistant stays down until you `ssh root@192.168.0.236` (LAN only) and unlock.
_: {
  disko.devices.disk.main = {
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        # EFI system partition — unencrypted /boot (systemd-boot + kernel + initrd)
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        # LUKS-encrypted root
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            # install-time passphrase source (nixos-anywhere --disk-encryption-keys);
            # NOT used at boot — you enter the passphrase over the initrd SSH session.
            passwordFile = "/tmp/luks.key";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
