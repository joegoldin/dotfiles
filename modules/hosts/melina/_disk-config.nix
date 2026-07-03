# disko spec for the mini PC: single 954 GB NVMe, UEFI. GPT: 1G ESP (/boot,
# systemd-boot) + ext4 root + 16 GiB swap tail. No encryption — the box must
# auto-boot unattended after a power loss (Home Assistant). disko ERASES
# /dev/nvme0n1; confirm the device name before deploy.
_: {
  disko.devices.disk.main = {
    device = "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
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
        root = {
          end = "-16G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
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
}
