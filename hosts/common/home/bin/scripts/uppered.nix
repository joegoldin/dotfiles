{
  name = "uppered";
  desc = "Convert stdin to uppercase";
  usage = "echo hi | uppered";
  fish = ''
    tr '[:lower:]' '[:upper:]'
  '';
}
