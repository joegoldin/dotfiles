{
  name = "claude-copy";
  desc = "Query clai raw with Claude Opus and copy to clipboard";
  type = "fish";
  body = ''
    set output (ai claude-raw $argv)
    echo "$output"
    echo "$output" | pbcopy
  '';
}
