# Placeholder hardware config for the misc VPS. nixos-anywhere
# --generate-hardware-config overwrites this with the real one on first install
# (commit it afterward). Mirrors racknerd-cloud-agent's qemu-guest profile.
{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  # fileSystems and boot loader are configured by disko
}
