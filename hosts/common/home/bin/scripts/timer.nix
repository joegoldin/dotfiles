{
  name = "timer";
  desc = "Set a timer with notification";
  usage = "timer DURATION";
  type = "fish";
  body = ''
    sleep $argv[1]
    sfx timer
    notify 'timer complete' $argv[1]
  '';
}
