{
  name = "cpwd";
  desc = "Copy working directory to clipboard";
  usage = "cpwd";
  type = "fish";
  body = ''
    pwd | tr -d '\n' | copy
  '';
}
