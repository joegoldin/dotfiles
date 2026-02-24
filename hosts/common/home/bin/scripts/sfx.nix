{
  name = "sfx";
  desc = "Play a sound effect";
  usage = "sfx NAME";
  type = "fish";
  body = ''
    exec mpv --really-quiet --no-video "$HOME/dotfiles/assets/sfx/$argv[1].ogg" &
  '';
}
