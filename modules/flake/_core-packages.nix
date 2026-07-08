# btop + gping + zmx on every box, system-wide — so even the lean servers that
# skip the home-manager cli-packages set (siofra, melina, erdtree, rennala,
# dectus, scarab, malenia) still get them. iputils provides the `ping` gping
# shells out to; there's no system-level inetutils to collide with, so no
# priority juggling needed here (that's only a concern in the workstation home
# profile). zmx is session persistence for SSH work — the lean servers are
# exactly where it matters (shell integration lives in modules/home/zmx.nix).
# Imported into every NixOS host via den.default.nixos.imports.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    btop
    gping
    iputils
    zmx
  ];
}
