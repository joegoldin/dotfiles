{
  name = "timer";
  desc = "Set a timer with notification";
  usage = "timer DURATION";
  examples = [
    { cmd = "timer 5m"; desc = "5 minute timer"; }
    { cmd = "timer 1h"; desc = "1 hour timer"; }
    { cmd = "timer 30"; desc = "30 second timer"; }
  ];
  fish = ''
    sleep $argv[1]
    sfx timer
    notify 'timer complete' $argv[1]
  '';
}
