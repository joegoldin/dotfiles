{
  name = "hoy";
  desc = "Print todays date (YYYY-MM-DD)";
  usage = "hoy";
  type = "fish";
  body = ''
    echo -n (date '+%Y-%m-%d')
  '';
}
