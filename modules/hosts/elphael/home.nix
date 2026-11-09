# Host-specific home config that isn't plasma (see ./plasma.nix for that):
# flatpaks, android tooling, desktop packages, python extras, dolphin places.
{ inputs, ... }:
{
  den.aspects.elphael.homeManager = {
    # Override Remmina's applet entry so it stays off at login.
    xdg.configFile."autostart/remmina-applet.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Remmina Applet
      Comment=Connect to remote desktops through the applet menu
      Icon=org.remmina.Remmina
      Exec=remmina -i
      Terminal=false
      Type=Application
      Hidden=true
    '';

    imports = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ./_android.nix
      ./_packages
      ./_python.nix
      ./_dolphin.nix
    ];
  };
}
