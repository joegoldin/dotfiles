{
  name = "claude-askinput";
  desc = "Pipe input to clai with Claude Opus";
  type = "fish";
  body = ''
    read input_lines
    set question (string join ' ' $argv)
    ai claude-ask "Given: \"$input_lines\"\n$question"
  '';
}
