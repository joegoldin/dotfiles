{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  goModule = import ../common/home/go.nix { inherit pkgs lib; };
  appImagePackages = import ../common/home/appimages.nix { inherit pkgs; };
  streamcontroller = import ../common/system/streamcontroller.nix { inherit pkgs; };
in
{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      affinity-v3
      unstable.calcurse
      cameractrls-gtk3
      chromedriver
      goModule.packages.claude-squad
      claude-container
      claude-desktop-fhs
      blip-caption
      bubblewrap
      unstable.cloudflared
      unstable.darktable
      # unstable.davinci-resolve
      unstable.discord
      unstable.ffmpeg
      # hyprwhspr
      docker-buildx
      unstable.dumbpipe
      unstable.gradle_9
      gcc15
      glibc
      inotify-tools
      unstable.jdk25_headless
      unstable.jellyfin-desktop
      # cargoModule.packages.litra
      # cargoModule.packages.litra-autotoggle
      libgcc
      localsend
      lotion
      unstable.maven
      unstable.obsidian
      unstable.parsec-bin
      pulseaudio # pactl required by pulsemeeter's pmctl script
      unstable.pulsemeeter
      unstable.pulsemixer
      rclone
      reptyr
      rocmPackages.amdsmi
      rocmPackages.rocminfo
      unstable.slack
      rocmPackages.rocm-smi
      streamcontroller.package
      sublime-merge
      unstable.tailscale
      ungoogled-chromium
      unstable.umu-launcher
      (unstable.unityhub.override {
        extraPkgs = ps: [
          ps.sqlite
          blip-caption
        ];
      })
      mpv
      nvtopPackages.amd
      unstable.vllm-rocm
      wl-clipboard
      xclip
      unstable.zoom-us
    ]
    ++ appImagePackages;

  xdg.configFile."autostart/StreamController.desktop".text = streamcontroller.autostartDesktopEntry;

  # PulseAudio device names; merged with the common audiomemo settings in
  # hosts/common/home/packages.nix.
  programs.audiomemo.settings = {
    record.device = "mic";
    devices = {
      mic = "alsa_input.usb-MOTU_M2_M20000044767-00.HiFi__Mic1__source";
      speakers = "alsa_output.usb-MOTU_M2_M20000044767-00.HiFi__Line1__sink.monitor";
    };
    device_groups.combo = [
      "mic"
      "speakers"
    ];
  };

  # Flatpak packages (installed via nix-flatpak)
  services.flatpak = {
    enable = true;
    packages = [ "com.bambulab.BambuStudio" ];
    update.onActivation = true;
    overrides."com.bambulab.BambuStudio".Environment.GTK_THEME = "Adwaita:dark";
  };

  # KDE doesn't push gtk-font-name into Flatpak sandboxes (XDG_CONFIG_HOME is
  # redirected to ~/.var/app/<id>/config), so GTK menus render as tofu. Pin
  # the font explicitly — Noto Sans ships in the freedesktop runtime.
  home.file.".var/app/com.bambulab.BambuStudio/config/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-font-name=Noto Sans 10
    gtk-theme-name=Adwaita
    gtk-application-prefer-dark-theme=true
  '';

  # Bambu Studio ships HarmonyOS Sans SC under /app/share/BambuStudio/fonts/
  # but fontconfig inside the Flatpak doesn't scan that dir, so the menu
  # font resolves to a fallback that can't render the glyphs (tofu). Point
  # fontconfig at the bundled font dir.
  home.file.".var/app/com.bambulab.BambuStudio/config/fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <dir>/app/share/BambuStudio/fonts</dir>
    </fontconfig>
  '';

  # The Flatpak's fontconfig cache is built before our fonts.conf is in
  # place (and again whenever nix-flatpak updates Bambu), leaving it stale
  # and menus tofu. Drop the cache so Bambu rebuilds it on next launch.
  home.activation.bambuStudioFontCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -rf "$HOME/.var/app/com.bambulab.BambuStudio/cache/fontconfig"
  '';
}
