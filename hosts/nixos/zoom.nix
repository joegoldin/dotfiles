{ pkgs, ... }:
let
  # Override zoom-us with the latest version and enable KDE portal support
  # for Wayland screen sharing. Native FHS package instead of Flatpak because
  # the Flatpak sandbox breaks Zoom's encrypted DB key derivation, causing
  # login to be lost on every launch.
  zoom = pkgs.zoom-us.override {
    plasma6XdgDesktopPortalSupport = true;
    targetPkgs = pkgs: [
      pkgs.libsecret
      pkgs.gnome-keyring
    ];
  };

  zoomLatest = zoom.overrideAttrs (old: {
    version = "6.7.5.6891";
    passthru = old.passthru // {
      unpacked = old.passthru.unpacked.overrideAttrs (_: {
        version = "6.7.5.6891";
        src = pkgs.fetchurl {
          url = "https://zoom.us/client/6.7.5.6891/zoom_x86_64.pkg.tar.xz";
          hash = "sha256-Qy4o3vbgiAjKUGWMFi8rNqyDAohG7TgwX69jKVWTWeY=";
        };
      });
    };
  });
in
{
  home.packages = [ zoomLatest ];
}
