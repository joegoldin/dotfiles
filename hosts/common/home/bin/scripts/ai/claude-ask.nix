{
  name = "claude-ask";
  desc = "Query clai using Claude Opus";
  type = "fish";
  body = ''
    clai -chat-model claude-3-opus-20240229 query $argv
  '';
}
