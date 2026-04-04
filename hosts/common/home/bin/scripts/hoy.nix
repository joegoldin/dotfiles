{
  name = "hoy";
  desc = "Print todays date (YYYY-MM-DD)";
  usage = "hoy";
  fish = ''
    echo -n (date '+%Y-%m-%d')
  '';
}
