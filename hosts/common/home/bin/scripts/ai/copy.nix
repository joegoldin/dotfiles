{
  name = "copy";
  desc = "Query clai raw and copy result to clipboard";
  type = "fish";
  body = ''
    set output (ai raw $argv)
    echo "$output"
    echo "$output" | pbcopy
  '';
}
