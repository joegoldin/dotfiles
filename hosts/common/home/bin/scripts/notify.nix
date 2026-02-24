{
  name = "notify";
  desc = "Send a desktop notification";
  usage = "notify [TITLE] [BODY]";
  type = "python";
  body = ''
    import subprocess
    import sys
    import json
    from datetime import datetime

    def try_exec(*args):
        """Try to execute a command. Return True if successful, False otherwise."""
        try:
            result = subprocess.run(args, capture_output=True)
            return result.returncode == 0
        except FileNotFoundError:
            return False

    def notify(title, description):
        # Try notify-send (Linux)
        if try_exec('notify-send', '--expire-time=5000', title, description):
            return

        # Try osascript (macOS)
        js = f"""
        var app = Application.currentApplication()
        app.includeStandardAdditions = true
        app.displayNotification({json.dumps(description)}, {{
            withTitle: {json.dumps(title)},
        }})
        """
        if try_exec('osascript', '-l', 'JavaScript', '-e', js):
            return

        # If nothing worked
        print("can't send notifications", file=sys.stderr)
        sys.exit(1)

    if __name__ == '__main__':
        title = sys.argv[1] if len(sys.argv) > 1 else "Notification"
        description = sys.argv[2] if len(sys.argv) > 2 else datetime.now().isoformat()

        notify(title, description)
  '';
}
