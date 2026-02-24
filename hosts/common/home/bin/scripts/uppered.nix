{
  name = "uppered";
  desc = "Convert stdin to uppercase";
  usage = "echo hi | uppered";
  type = "fish";
  body = ''
    tr '[:lower:]' '[:upper:]'
  '';
}
