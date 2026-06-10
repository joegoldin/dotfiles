{ lib, ... }:
{
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
