{
  username,
  lib,
  config,
  pkgs,
  ...
}: {
  nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
  networking.domain = "subnet02180136.vcn02180136.oraclevcn.com";
}
