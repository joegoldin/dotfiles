# LUKS-encrypted root, unlocked remotely over SSH in the initrd (see machine.nix).
# Bare-metal PLACEHOLDER: assumes a single BIOS/GPT disk at /dev/sda. Layout:
# EF02 GRUB stub + UNENCRYPTED /boot + the LUKS container filling the rest; swap
# is a 16 GiB swapfile on the encrypted root (machine.nix). CONFIRM at provision:
# real device (/dev/sda vs nvme), BIOS vs UEFI (swap EF02 → ESP + systemd-boot if
# UEFI), and multi-disk/RAID layout. Passphrase set at install via
# nixos-anywhere --disk-encryption-keys; typed over initrd SSH on every boot.
_: {
  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        # GRUB BIOS boot partition
        boot = {
          size = "1M";
          type = "EF02";
        };
        # Unencrypted /boot — GRUB loads the kernel + initrd from here, then the
        # initrd unlocks the LUKS root (so GRUB never touches LUKS).
        bootfs = {
          size = "1G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/boot";
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
