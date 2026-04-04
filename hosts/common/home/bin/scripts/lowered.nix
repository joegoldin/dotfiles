{
  name = "lowered";
  desc = "Convert stdin to lowercase";
  usage = "echo HI | lowered";
  fish = ''
    tr '[:upper:]' '[:lower:]'
  '';
}
