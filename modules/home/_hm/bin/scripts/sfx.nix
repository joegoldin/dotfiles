{
  name = "sfx";
  desc = "Play a sound effect";
  params = [
    {
      name = "NAME";
      desc = "Sound effect to play";
      completions = "ls $HOME/dotfiles/assets/sfx/ 2>/dev/null | string replace -r '\\.ogg$' ''";
    }
  ];
  examples = [
    { cmd = "sfx level-up"; desc = "Play level-up sound"; }
    { cmd = "sfx timer -V 50"; desc = "Play timer at 50% volume"; }
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
  fish = ''
    pw-play --volume $_flag_volume "$HOME/dotfiles/assets/sfx/$argv[1].ogg" &
  '';
}
