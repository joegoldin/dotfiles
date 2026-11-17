# Shared by NixOS and nix-darwin; no Ghostty GUI or Zig build on remote hosts.
{ pkgs, ... }:
{
  environment.systemPackages = [ (pkgs.callPackage ./_pkgs/ghostty-terminfo.nix { }) ];
}
