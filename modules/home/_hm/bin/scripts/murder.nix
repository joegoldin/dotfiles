{
  name = "murder";
  desc = "Kill processes by pid, name, or port";
  params = [{ name = "TARGET"; desc = "PID, process name, or :PORT"; }];
  flags = [
    {
      name = "--dry-run";
      short = "-d";
      desc = "Show matching processes without killing";
      bool = true;
    }
  ];
  examples = [
    { cmd = "murder 1234"; desc = "Kill process by PID"; }
    { cmd = "murder node"; desc = "Kill processes matching 'node'"; }
    { cmd = "murder :8080"; desc = "Kill process on port 8080"; }
    { cmd = "murder -d node"; desc = "Show matching processes only"; }
  ];
  python = ''
    import os
    import subprocess
    import time

    SIGNALS = [
        [15, 3],  # SIGTERM, wait 3s
        [2, 3],   # SIGINT, wait 3s
        [1, 4],   # SIGHUP, wait 4s
        [9, 0]    # SIGKILL, no wait
    ]

    dry_run = _args.dry_run

    def is_int(arg):
        try:
            int(arg)
            return True
        except ValueError:
            return False

    def running(pid):
        try:
            result = subprocess.run(['ps', '-p', str(pid)], capture_output=True, text=True)
            return len(result.stdout.strip().split('\n')) == 2
        except:
            return False

    def go_ahead():
        if dry_run:
            return False
        try:
            response = input().strip().lower()
            return response in ['y', 'yes', 'yas']
        except (EOFError, KeyboardInterrupt):
            return False

    def kill_process(pid, code):
        try:
            subprocess.run(['kill', f'-{code}', str(pid)], check=False)
        except:
            pass

    def murder_pid(pid):
        ps_result = subprocess.run(
            ['ps', '-p', str(pid), '-o', 'command='],
            capture_output=True, text=True
        )
        name = ps_result.stdout.strip() or f"pid {pid}"
        print(f"  {name} (pid {pid})")
        if dry_run:
            return
        for signal_code, wait_time in SIGNALS:
            if not running(pid):
                break
            kill_process(pid, signal_code)
            time.sleep(0.5)
            if running(pid):
                time.sleep(wait_time)

    def murder_names(name):
        while True:
            should_loop = False

            try:
                result = subprocess.run(
                    f"ps -eo 'pid command' | grep -Fiw '{name}' | grep -Fv grep",
                    shell=True,
                    capture_output=True,
                    text=True
                )

                for line in result.stdout.strip().split('\n'):
                    if not line:
                        continue

                    parts = line.split(None, 1)
                    if len(parts) < 2:
                        continue

                    pid_str, fullname = parts
                    pid = int(pid_str)

                    if pid == os.getpid():
                        continue

                    if dry_run:
                        print(f"  {fullname.strip()} (pid {pid})")
                        continue

                    print(f"murder {fullname.strip()} (pid {pid})? ", end="", flush=True)
                    if go_ahead():
                        murder_pid(pid)
                        should_loop = True
                        break
            except:
                break

            if not should_loop:
                break

    def murder_port(arg):
        while True:
            should_loop = False

            try:
                result = subprocess.run(['lsof', '-i', arg], capture_output=True, text=True)
                lines = result.stdout.strip().split('\n')

                for line in lines[1:]:  # Skip header
                    if not line:
                        continue

                    parts = line.split(None, 2)
                    if len(parts) < 2:
                        continue

                    pid_str = parts[1]

                    ps_result = subprocess.run(
                        ['ps', '-eo', 'command', pid_str],
                        capture_output=True,
                        text=True
                    )
                    fullname_lines = ps_result.stdout.strip().split('\n')
                    if len(fullname_lines) < 2:
                        continue

                    fullname = fullname_lines[1]

                    if dry_run:
                        print(f"  {fullname.strip()} (pid {pid_str})")
                        continue

                    print(f"murder {fullname.strip()} (pid {pid_str})? ", end="", flush=True)
                    if go_ahead():
                        murder_pid(int(pid_str))
                        should_loop = True
                        break
            except:
                break

            if not should_loop:
                break

    def murder(arg):
        is_pid = is_int(arg)
        is_port = arg[0] == ':' and len(arg) > 1 and is_int(arg[1:])

        if is_pid:
            murder_pid(int(arg))
        elif is_port:
            murder_port(arg)
        else:
            murder_names(arg)

    for arg in [_args.target]:
        murder(arg)
  '';
}
