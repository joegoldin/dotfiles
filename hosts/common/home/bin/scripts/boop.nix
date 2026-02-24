{
  name = "boop";
  desc = "Play a sound based on last exit status";
  usage = "some-command; boop";
  type = "function";
  body = ''
    set last $status
    if test $last -eq 0
        sfx good
    else
        sfx bad
    end
    return $last
  '';
}
