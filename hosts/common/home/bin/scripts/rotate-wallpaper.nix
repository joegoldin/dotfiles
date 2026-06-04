{
  name = "rotate-wallpaper";
  desc = "Rotate the desktop wallpaper to a new random image";
  usage = "rotate-wallpaper";
  fish = ''
    echo "Rotating wallpaper…"
    systemctl --user start set-wallpaper.service
    and echo "Wallpaper rotated."
  '';
}
