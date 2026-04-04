{
  name = "line";
  desc = "Print the Nth line of stdin";
  params = [{ name = "N"; desc = "Line number to print"; }];
  fish = ''
    head -n $argv[1] | tail -n 1
  '';
}
