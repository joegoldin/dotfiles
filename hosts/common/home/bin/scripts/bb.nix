{
  name = "bb";
  desc = "Run a command in the background silently";
  params = [{ name = "COMMAND"; desc = "Command to run in background"; }];
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
