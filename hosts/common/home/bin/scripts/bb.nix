{
  name = "bb";
  desc = "Run a command in the background silently";
  usage = "bb COMMAND...";
  type = "fish";
  body = ''
    if isatty stdout
        exec >/dev/null
    end

    if isatty stderr
        exec 2>/dev/null
    end

    $argv &
  '';
}
