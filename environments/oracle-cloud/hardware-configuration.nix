{modulesPath, ...}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];
  boot = {
    tmp = {
      useTmpfs = true;
      tmpfsSize = "10G";
      cleanOnBoot = true;
    };
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6536-F6CE";
    fsType = "vfat";
  };
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront"];
  boot.initrd.kernelModules = ["nvme"];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  zramSwap.enable = true;
}
