{
  name = "ask";
  desc = "Query clai with a question";
  type = "fish";
  body = ''
    clai query $argv
  '';
}
