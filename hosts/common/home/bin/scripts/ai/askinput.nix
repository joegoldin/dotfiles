{
  name = "askinput";
  desc = "Pipe input to clai with a question";
  type = "fish";
  body = ''
    read input_lines
    set question (string join ' ' $argv)
    ai ask "Given: \"$input_lines\"\n$question"
  '';
}
