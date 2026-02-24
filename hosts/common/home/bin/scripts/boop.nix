{
  name = "boop";
  desc = "Play a sound based on last exit status";
  usage = "some-command; boop";
  type = "function";
  body = ''
    set last $status
    if test $last -eq 0
        sfx level-up
    else
        sfx error
    end
    return $last
  '';
}
