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
      arg = "VOL";
      desc = "Volume 0-1.0 (default 1.0)";
    }
  ];
  body = ''
    set -l vol 1.0
    if set -l idx (contains -i -- --volume $argv)
        set vol $argv[(math $idx + 1)]
        set -e argv[$idx]
        set -e argv[$idx]
    end

    pw-play --volume $vol "$HOME/dotfiles/assets/sfx/$argv[1].ogg" &
  '';
}
