# disko spec — PLACEHOLDER for the bare-metal dedicated server. This assumes a
# single BIOS/GPT disk at /dev/sda with a 32 GiB swap tail. CONFIRM at provision
# time: real device name (/dev/sda vs /dev/nvme0n1), BIOS vs UEFI (swap the EF02
# BIOS-boot partition for an ESP + systemd-boot if UEFI), and whether you want a
# multi-disk / RAID / separate data-volume layout for game + HPC data. disko
# ERASES this disk.
_: {
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";
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
              end = "-32G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            # Swap partition (~32 GiB; plenty with 192 GB RAM)
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
