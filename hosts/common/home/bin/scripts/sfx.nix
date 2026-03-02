{
  name = "sfx";
  desc = "Play a sound effect";
  type = "fish";
  params = [
    {
      name = "NAME";
      desc = "Sound effect to play";
      completions = "ls $HOME/dotfiles/assets/sfx/ 2>/dev/null | string replace -r '\\.ogg$' ''";
    }
  ];
  body = ''
    exec mpv --really-quiet --no-video "$HOME/dotfiles/assets/sfx/$argv[1].ogg" &
  '';
}
