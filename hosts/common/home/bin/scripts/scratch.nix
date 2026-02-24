{
  name = "scratch";
  desc = "Open a scratch file in your editor";
  usage = "scratch";
  type = "fish";
  body = ''
    set file (mktemp)
    echo "Editing $file"
    exec $EDITOR $file
  '';
}
