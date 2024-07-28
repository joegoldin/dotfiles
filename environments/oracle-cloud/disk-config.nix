{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-path/scsi-360d8fe3943ad4341a727520e9a5e1138";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              end = "4G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              name = "root";
              end = "-12G";
              content = {
                type = "filesystem";
                format = "bcachefs";
                mountpoint = "/";
              };
            };
            encryptedSwap = {
              size = "6G";
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100; # prefer to encrypt as long as we have space for it
              };
            };
            plainSwap = {
              size = "100%";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true; # resume from hiberation from this device
              };
            };
          };
        };
      };
    };
  };
}
