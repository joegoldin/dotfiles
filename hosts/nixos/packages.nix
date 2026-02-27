{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  goModule = import ../common/home/go.nix { inherit pkgs lib; };
  appImagePackages = import ../common/home/appimages.nix { inherit pkgs; };
  streamcontroller-wrapped = unstable.streamcontroller.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/streamcontroller \
        --set GSK_RENDERER ngl
    '';
  });
in
{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      # affinity-nix.packages.x86_64-linux.photo
      # unstable.android-studio-full
      unstable.calcurse
      chromedriver
      goModule.packages.claude-squad
      claude-desktop
      unstable.cloudflared
      #      unstable.davinci-resolve
      unstable.discord
      unstable.dumbpipe
      # extraterm
      # ghostty is managed by programs.ghostty in ghostty.nix
      inotify-tools
      # unstable.jellyfin-media-player
      #      cargoModule.packages.litra
      #      cargoModule.packages.litra-autotoggle
      lotion
      unstable.obsidian
      unstable.parsec-bin
      pulseaudio # pactl required by pulsemeeter's pmctl script
      unstable.pulsemeeter
      unstable.pulsemixer
      reptyr
      unstable.slack
      streamcontroller-wrapped
      sublime-merge
      unstable.tailscale
      ungoogled-chromium
      mpv
      # unstable.vllm # disabled: torchaudio/compressed-tensors build failures in nixpkgs-unstable
      wl-clipboard
      xclip
    ]
    ++ appImagePackages;

  # Flatpak packages (installed via nix-flatpak)
  services.flatpak = {
    enable = true;
    packages = [
      "us.zoom.Zoom"
    ];
  };
}
