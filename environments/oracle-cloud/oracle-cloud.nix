{
  username,
  lib,
  config,
  pkgs,
  ...
}: {
  nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
  networking.domain = "";
}
