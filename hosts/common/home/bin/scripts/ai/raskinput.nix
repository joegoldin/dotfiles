{
  name = "raskinput";
  desc = "Pipe input and reply to previous clai conversation";
  type = "fish";
  body = ''
    read input_lines
    set question (string join ' ' $argv)
    ai rask "Given: \"$input_lines\"\n$question"
  '';
}
