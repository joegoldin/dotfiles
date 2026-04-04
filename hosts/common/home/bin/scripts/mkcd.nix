{
  name = "mkcd";
  desc = "Create a directory and cd into it";
  usage = "mkcd DIR";
  function = ''
    mkdir -p $argv[1]
    cd $argv[1]
  '';
}
