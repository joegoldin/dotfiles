{
  name = "waitfor";
  desc = "Wait for a process to finish";
  usage = "waitfor PID";
  type = "fish";
  body = ''
    set pid $argv[1]

    if command -v caffeinate >/dev/null
        caffeinate -w $pid
    else if command -v systemd-inhibit >/dev/null
        systemd-inhibit \
            --who=waitfor \
            --why="Awaiting PID $pid" \
            tail --pid=$pid -f /dev/null
    else
        tail --pid=$pid -f /dev/null
    end
  '';
}
