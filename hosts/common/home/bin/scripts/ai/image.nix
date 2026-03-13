{
  name = "image";
  desc = "Query clai with a photo from ~/Downloads";
  type = "fish";
  body = ''
    clai -photo-dir ~/Downloads photo $argv
  '';
}
