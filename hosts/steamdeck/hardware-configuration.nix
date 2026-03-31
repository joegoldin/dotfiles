# hosts/steamdeck/hardware-configuration.nix
# Placeholder — will be replaced by nixos-generate-config on the Steam Deck
{
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
