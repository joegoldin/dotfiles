{
  name = "mkcd";
  desc = "Create a directory and cd into it";
  params = [{ name = "DIR"; desc = "Directory to create"; }];
  function = ''
    mkdir -p $argv[1]
    cd $argv[1]
  '';
}
