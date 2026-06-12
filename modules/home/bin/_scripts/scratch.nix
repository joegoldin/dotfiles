{
  name = "scratch";
  desc = "Open a scratch file in your editor";
  usage = "scratch";
  fish = ''
    set file (mktemp)
    echo "Editing $file"
    exec $EDITOR $file
  '';
}
