{
  name = "claude-rask";
  desc = "Reply to previous clai conversation using Claude Opus";
  type = "fish";
  body = ''
    clai -chat-model claude-3-opus-20240229 -reply query $argv
  '';
}
