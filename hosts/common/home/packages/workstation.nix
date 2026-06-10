# Heavier dev tooling shared between workstations (darwin, joe-desktop,
# office-pc). NOT imported by ./default.nix — workstation hosts import this
# file explicitly so cloud VMs stay lean.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    cloudflared
    cmake
    croc
    dive
    docker-compose
    entr
    fastfetch
    kubefwd
    nodejs
    protobuf
    sops
    sshpass
    stern
    timg
    universal-ctags
    visidata
    watchman
  ];
}
