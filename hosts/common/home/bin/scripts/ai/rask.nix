{
  name = "rask";
  desc = "Reply to previous clai conversation";
  type = "fish";
  body = ''
    clai -reply query $argv
  '';
}
