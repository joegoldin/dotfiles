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
            # Root filesystem
            root = {
              end = "-2G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            # Swap partition
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
