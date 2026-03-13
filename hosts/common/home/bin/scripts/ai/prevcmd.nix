{
  name = "prevcmd";
  desc = "Ask about the previous shell command";
  type = "fish";
  body = ''
    set question (string join ' ' $argv)
    ai ask "Previous Command: $history[1] \nGiven: $question"
  '';
}
