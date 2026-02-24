{
  name = "murder";
  desc = "Kill processes by pid, name, or port";
  usage = "murder PID|NAME|:PORT";
  type = "python";
  body = ''
    import os
    import subprocess
    import sys
    import time

    SIGNALS = [
        [15, 3],  # SIGTERM, wait 3s
        [2, 3],   # SIGINT, wait 3s
        [1, 4],   # SIGHUP, wait 4s
        [9, 0]    # SIGKILL, no wait
    ]

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

    if __name__ == '__main__':
        if len(sys.argv) < 2:
            print('usage:')
            print('murder 123    # kill by pid')
            print('murder ruby   # kill by process name')
            print('murder :3000  # kill by port')
            sys.exit(1)

        for arg in sys.argv[1:]:
            murder(arg)
  '';
}
