# LUKS-encrypted root, unlocked remotely over SSH in the initrd (see machine.nix).
# BIOS/GPT layout: EF02 GRUB stub + an UNENCRYPTED /boot (GRUB reads the kernel +
# initrd from here) + the LUKS container filling the rest. Swap is an 8 GiB
# swapfile on the encrypted root (machine.nix). The passphrase is set at install
# via `nixos-anywhere --disk-encryption-keys`; you type it over the initrd SSH
# session on every boot. Confirm the disk device (/dev/vda) before deploy.
_: {
  disko.devices.disk.main = {
    device = "/dev/vda";
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
