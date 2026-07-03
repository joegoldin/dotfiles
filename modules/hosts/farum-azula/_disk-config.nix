# LUKS-encrypted root, unlocked remotely over SSH in the initrd (see machine.nix).
# Oracle Cloud Ampere ARM64 (A1.Flex), single boot volume /dev/sda, UEFI. GPT: 1G
# ESP (/boot — systemd-boot + kernel + initrd, unencrypted so the initrd can unlock
# LUKS) + the LUKS container filling the rest. Swap is an 8 GiB swapfile on the
# encrypted root (machine.nix). Passphrase set at install via nixos-anywhere
# --disk-encryption-keys; typed over the initrd SSH session on every boot. disko
# ERASES /dev/sda.
#
# NOTE: encrypted means the box does NOT auto-boot after a stop/restart — it halts
# in the initrd until you `ssh root@farum-azula.turnin.quest` and unlock.
_: {
  disko.devices.disk.main = {
    device = "/dev/sda";
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
