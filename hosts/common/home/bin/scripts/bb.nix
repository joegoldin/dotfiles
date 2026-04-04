{
  name = "bb";
  desc = "Run a command in the background silently";
  usage = "bb COMMAND...";
  examples = [
    { cmd = "bb firefox"; desc = "Launch firefox in background"; }
    { cmd = "bb make build"; desc = "Run build silently"; }
  ];
  fish = ''
    if isatty stdout
        exec >/dev/null
    end

    if isatty stderr
        exec 2>/dev/null
    end

    $argv &
  '';
}
