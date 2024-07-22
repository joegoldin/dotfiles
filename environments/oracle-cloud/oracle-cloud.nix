{
  username,
  lib,
  config,
  pkgs,
  ...
}: {
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.domain = "subnet02180136.vcn02180136.oraclevcn.com";
}
