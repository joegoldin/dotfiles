{
  name = "line";
  desc = "Print the Nth line of stdin";
  usage = "cat file | line N";
  fish = ''
    head -n $argv[1] | tail -n 1
  '';
}
