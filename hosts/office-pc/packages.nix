# Packages unique to office-pc — shared linux-workstation packages live in
# hosts/common/home/packages/linux-workstation.nix, cross-platform tools in
# hosts/common/home/packages/{default,workstation}.nix.
{ pkgs, lib, ... }:
{
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
    pkgs.unstable.vllm-rocm
  ];
}
