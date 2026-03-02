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
  flags = [
    {
      name = "--volume";
      short = "-V";
      arg = "VOL";
      desc = "Volume 0-1.0 (default 1.0)";
      default = "1.0";
    }
  ];
  body = ''
    pw-play --volume $_flag_volume "$HOME/dotfiles/assets/sfx/$argv[1].ogg" &
  '';
}
