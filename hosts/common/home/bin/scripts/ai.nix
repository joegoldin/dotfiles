{
  name = "ai";
  desc = "Query Claude from the command line";
  flags = [
    {
      name = "--reply";
      short = "-r";
      desc = "Continue the most recent conversation";
      bool = true;
    }
    {
      name = "--raw";
      desc = "No markdown formatting";
      bool = true;
    }
    {
      name = "--copy";
      short = "-c";
      desc = "Copy result to clipboard";
      bool = true;
    }
  ];
  fish = ''
    set -l flags --bare -p
    if set -q _flag_reply
      set -a flags -c
    end
    if set -q _flag_raw
      set -a flags --append-system-prompt "Respond in plain text without any markdown formatting."
    end

    if set -q _flag_copy
      if not isatty stdin
        set -l input (cat)
        set output (printf '%s' "$input" | claude $flags (string join ' ' $argv))
      else
        set output (claude $flags (string join ' ' $argv))
      end
      echo "$output"
      echo "$output" | copy
    else
      claude $flags (string join ' ' $argv)
    end
  '';
}
