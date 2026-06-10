# Linux-ONLY home packages for office-pc — cross-platform tools come from
# hosts/common/home/packages/{default,workstation}.nix.
{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  streamcontroller = import ../common/system/streamcontroller.nix { inherit pkgs; };

  packageGroups = with pkgs; {
    cli = [
      docker-buildx
      inotify-tools
      nvtopPackages.amd
      pulseaudio # pactl required by pulsemeeter's pmctl script
      unstable.pulsemixer
      rocmPackages.amdsmi
      rocmPackages.rocminfo
      streamcontroller.package
      unstable.tailscale
      unstable.umu-launcher
      unstable.vllm-rocm
      wl-clipboard
      xclip
    ];

    gui = [
      localsend
      unstable.pulsemeeter
      ungoogled-chromium
    ];
  };
in
{
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isx86_64 (
    lib.flatten (lib.attrValues packageGroups)
  );

  xdg.configFile."autostart/StreamController.desktop".text = streamcontroller.autostartDesktopEntry;
}
