{
  name = "raw";
  desc = "Query clai with raw output (no formatting)";
  type = "fish";
  body = ''
    clai -raw query $argv
  '';
}
