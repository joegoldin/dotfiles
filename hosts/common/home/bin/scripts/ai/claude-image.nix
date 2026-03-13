{
  name = "claude-image";
  desc = "Query clai with a photo using Claude Opus";
  type = "fish";
  body = ''
    clai -chat-model claude-3-opus-20240229 -photo-dir ~/Downloads photo $argv
  '';
}
