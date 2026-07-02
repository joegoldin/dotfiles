# disko spec for the misc VPS: GPT, 1M EF02 BIOS-boot, ext4 root, swap tail.
# Hardware not yet discovered — confirm /dev/vda vs /dev/sda and BIOS vs UEFI at
# provision (`lsblk`, `ls /sys/firmware/efi`). disko ERASES this disk.
_: {
  disko.devices = {
    disk = {
      main = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # GRUB BIOS boot partition
            boot = {
              size = "1M";
              type = "EF02"; # BIOS boot partition
            };
            # Root filesystem (fills the disk minus the swap tail)
            root = {
              end = "-8G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            # Swap partition (~8 GiB)
            swap = {
              size = "100%";
              content = {
                type = "swap";
                discardPolicy = "both";
              };
            };
          };
        };
      };
    };
  };
}
