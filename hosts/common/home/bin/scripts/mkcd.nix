{
  name = "mkcd";
  desc = "Create a directory and cd into it";
  usage = "mkcd DIR";
  type = "function";
  body = ''
    mkdir -p $argv[1]
    cd $argv[1]
  '';
}
