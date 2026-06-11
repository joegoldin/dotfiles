{ pkgs }:
{
  name = "filewatch";
  desc = "Run a command when files change";
  usage = "filewatch PATTERN -- COMMAND...";
  params = [
    { name = "PATTERN"; desc = "Glob pattern to watch (e.g. 'src/**/*.js')"; }
  ];
  flags = [
    { name = "clear"; short = "c"; bool = true; desc = "Clear screen between runs"; }
    { name = "restart"; short = "r"; bool = true; desc = "Restart long-running command on change (instead of waiting for exit)"; }
  ];
  examples = [
    { cmd = "filewatch '*.js' -- make build"; desc = "Rebuild on JS changes"; }
    { cmd = "filewatch -r 'src/**/*.py' -- python app.py"; desc = "Restart server on change"; }
    { cmd = "filewatch -c '*.ts' -- npm test"; desc = "Clear and run tests on change"; }
    { cmd = "find src -name '*.js' | filewatch -- make build"; desc = "Pipe file list directly"; }
  ];
  runtimeInputs = [ pkgs.entr ];
  fish = ''
    # Separate PATTERN from COMMAND at --
    set dash_idx 0
    for i in (seq (count $argv))
        if test "$argv[$i]" = --
            set dash_idx $i
            break
        end
    end

    if test $dash_idx -eq 0
        echo "usage: filewatch PATTERN -- COMMAND..." >&2
        echo "       ... | filewatch -- COMMAND..." >&2
        return 1
    end

    # Build entr flags
    set entr_flags
    if test "$_flag_clear" = true
        set -a entr_flags -c
    end
    if test "$_flag_restart" = true
        set -a entr_flags -r
    end

    # Command is everything after --
    set cmd_start (math $dash_idx + 1)
    set cmd $argv[$cmd_start..-1]

    if test $dash_idx -gt 1
        # Pattern provided as argument - use find/glob
        set pattern $argv[1]
        while true
            # Use fish glob to expand the pattern
            set files (eval "printf '%s\\n' $pattern" 2>/dev/null)
            if test (count $files) -eq 0
                echo "filewatch: no files match '$pattern'" >&2
                return 1
            end
            printf '%s\n' $files | entr $entr_flags -d $cmd
            # entr -d exits when new files appear; loop to pick them up
            or break
        end
    else
        # No pattern - read file list from stdin
        if isatty stdin
            echo "filewatch: provide a pattern or pipe file list to stdin" >&2
            return 1
        end
        entr $entr_flags $cmd
    end
  '';
}
