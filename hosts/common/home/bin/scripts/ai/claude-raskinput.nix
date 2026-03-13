{
  name = "claude-raskinput";
  desc = "Pipe input and reply using Claude Opus";
  type = "fish";
  body = ''
    read input_lines
    set question (string join ' ' $argv)
    ai claude-rask "Given: \"$input_lines\"\n$question"
  '';
}
