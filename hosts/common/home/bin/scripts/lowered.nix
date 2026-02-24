{
  name = "lowered";
  desc = "Convert stdin to lowercase";
  usage = "echo HI | lowered";
  type = "fish";
  body = ''
    tr '[:upper:]' '[:lower:]'
  '';
}
