{
  name = "getsong";
  desc = "Download best audio with yt-dlp";
  usage = "getsong URL";
  type = "fish";
  body = ''
    exec yt-dlp -f bestaudio -o '%(title)s.%(ext)s' $argv
  '';
}
