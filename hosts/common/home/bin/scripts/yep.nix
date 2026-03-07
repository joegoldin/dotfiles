{
  name = "yep";
  desc = "YepAnywhere client control";
  type = "bash";
  autoparse = false;
  params = [
    {
      name = "command";
      desc = "on | off | open | status | logs";
      required = false;
    }
  ];
  body = ''
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
