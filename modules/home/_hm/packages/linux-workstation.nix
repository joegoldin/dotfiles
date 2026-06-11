# Packages shared by the linux workstations (joe-desktop, office-pc) but not
# macOS or the cloud hosts. Imported explicitly by those hosts alongside
# ./workstation.nix. Host packages files keep only what is unique to that
# machine.
{ pkgs, lib, ... }:
let
  inherit (pkgs) unstable;
  streamcontroller = import ../../../system/_sys/streamcontroller.nix { inherit pkgs; };

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
      # unstable.vllm-rocm # broken rn, needs updates (also marked insecure in unstable)
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
