{
  name = "getsong";
  desc = "Download best audio with yt-dlp";
  params = [{ name = "URL"; desc = "YouTube URL to download"; }];
  fish = ''
    exec yt-dlp -f bestaudio -o '%(title)s.%(ext)s' $argv
  '';
}
