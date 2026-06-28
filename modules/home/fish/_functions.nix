{
  # Disable greeting
  fish_greeting = "echo '🐟'";

  # Custom history expansion functions (replacing puffer-fish plugin)
  __expand_bang = ''
    switch (commandline -t)
      case '!'
        commandline -t $history[1]
      case '*'
        commandline -i '!'
    end
  '';

  __expand_lastarg = ''
    switch (commandline -t)
      case '!'
        # Get all tokens except the last one from the previous command
        set -l tokens (string split ' ' -- $history[1])
        set -l cmd_without_last (string join ' ' $tokens[1..-2])
        commandline -t $cmd_without_last
      case '*'
        commandline -i '.'
    end
  '';
}
