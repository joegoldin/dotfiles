{
  name = "yep";
  desc = "YepAnywhere client control";
  autoparse = false;
  examples = [
    { cmd = "yep on"; desc = "Start the service"; }
    { cmd = "yep off"; desc = "Stop the service"; }
    { cmd = "yep status"; desc = "Check service status"; }
    { cmd = "yep logs"; desc = "View service logs"; }
  ];
  params = [
    {
      name = "command";
      desc = "on | off | open | status | logs";
      required = false;
    }
  ];
  bash = ''
    cmd="''${1:-help}"

    case "$cmd" in
      on)
        sudo systemctl start yepanywhere
        systemctl status yepanywhere --no-pager
        ;;
      off)
        sudo systemctl stop yepanywhere
        systemctl status yepanywhere --no-pager
        ;;
      open)
        xdg-open http://localhost:3400/
        ;;
      status)
        systemctl status yepanywhere --no-pager
        ;;
      logs)
        journalctl -u yepanywhere -f
        ;;
      help|-h|--help)
        usage
        ;;
      *)
        die "Unknown command: $cmd"
        ;;
    esac
  '';
}
