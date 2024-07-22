{
  username,
  lib,
  config,
  pkgs,
  ...
}: {
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.domain = "subnet02180136.vcn02180136.oraclevcn.com";
}
