{
  name = "each";
  desc = "Run each stdin line through a command";
  usage = "echo -e 'a\\nb' | each 'echo {}'";
  type = "python-argparse";
  body = ''
    import argparse
    import re
    import shlex
    import subprocess
    import sys


    def eprint(*args):
        """Print to stderr."""
        print(*args, file=sys.stderr)


    def parse_args():
        """Parse command line arguments."""
        parser = argparse.ArgumentParser(
            description="Run each line through a command. An easier `xargs`.",
        )
        parser.add_argument(
            "command", type=str, help="The command to run, such as `cat {}`."
        )
        result = parser.parse_args()
        if "{}" not in result.command:
            eprint("command must contain at least one {}")
            sys.exit(1)
        return result


    def delimiters_to_re(delimiters):
        """Convert list of delimiters to a compiled regex pattern."""
        escaped = map(re.escape, delimiters)
        re_str = "|".join(escaped)
        return re.compile(re_str)


    def run(command_template, command_arg):
        """Run the command with the given argument substituted for {}."""
        result = subprocess.run(
            command_template.replace("{}", shlex.quote(command_arg)),
            stdin=sys.stdin,
            stdout=sys.stdout,
            stderr=sys.stderr,
            shell=True,
            text=False,
            check=False,
        )
        if result.returncode != 0:
            sys.exit(result.returncode)


    def main():
        """Main entry point."""
        args = parse_args()

        delimiters = ["\n", "\r"]
        delimiters_re = delimiters_to_re(delimiters)

        all_stdin = sys.stdin.read()
        command_args = delimiters_re.split(all_stdin)

        for command_arg in command_args:
            if command_arg == "":
                continue
            run(
                command_template=args.command,
                command_arg=command_arg,
            )


    if __name__ == "__main__":
        main()
  '';
}
