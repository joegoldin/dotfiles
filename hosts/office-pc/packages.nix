{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
in
{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      docker-buildx
      inotify-tools
      nvtopPackages.amd
      rocmPackages.amdsmi
      rocmPackages.rocminfo
      unstable.cloudflared
      unstable.tailscale
      unstable.vllm
      wl-clipboard
    ];
}
