{
  name = "cpwd";
  desc = "Copy working directory to clipboard";
  usage = "cpwd";
  fish = ''
    pwd | tr -d '\n' | copy
  '';
}
