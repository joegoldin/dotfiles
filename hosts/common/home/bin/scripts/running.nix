{
  name = "running";
  desc = "List running processes, optionally filtered";
  usage = "running [PATTERN]";
  type = "fish";
  body = ''
    set process_list (ps -eo 'pid command')
    if test (count $argv) -gt 0
        set process_list (string match -r ".*$argv.*" $process_list)
    end

    for line in $process_list
        echo $line
    end | \
        grep -Fv (status current-filename) | \
        grep -Fv grep | \
        env GREP_COLORS='mt=00;35' grep -E --colour=auto '^\s*[[:digit:]]+'
  '';
}
