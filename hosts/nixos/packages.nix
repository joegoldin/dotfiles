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

  # home.file would symlink these into ~/.var/app/.../config/ pointing at
  # /nix/store/...-home-manager-files/..., but that store path isn't
  # accessible inside the Bambu Studio flatpak sandbox — the symlinks
  # dangle, fontconfig/GTK silently skip them, and menus render as tofu.
  # Write real files via activation so the sandbox can actually read them.
  #   - settings.ini: KDE doesn't push gtk-font-name into Flatpak sandboxes,
  #     pin Noto Sans (ships in the freedesktop runtime).
  #   - fonts.conf: Bambu ships HarmonyOS Sans SC under /app/share/BambuStudio/fonts
  #     but fontconfig doesn't scan that dir by default.
  #   - cache wipe: nix-flatpak rebuilds the fontconfig cache on each update,
  #     leaving it stale; drop it so Bambu rebuilds on next launch.
  home.activation.bambuStudioConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    d="$HOME/.var/app/com.bambulab.BambuStudio/config"
    mkdir -p "$d/gtk-3.0" "$d/fontconfig"
    rm -f "$d/gtk-3.0/settings.ini" "$d/fontconfig/fonts.conf"
    cat > "$d/gtk-3.0/settings.ini" <<'EOF'
    [Settings]
    gtk-font-name=Noto Sans 10
    gtk-theme-name=Adwaita
    gtk-application-prefer-dark-theme=true
    EOF
    cat > "$d/fontconfig/fonts.conf" <<'EOF'
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <dir>/app/share/BambuStudio/fonts</dir>
    </fontconfig>
    EOF
    rm -rf "$HOME/.var/app/com.bambulab.BambuStudio/cache/fontconfig"
  '';
}
