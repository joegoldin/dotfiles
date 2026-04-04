{
  name = "shrinkvid";
  desc = "Shrink a video with ffmpeg";
  usage = "shrinkvid INPUT OUTPUT [CRF]";
  examples = [
    { cmd = "shrinkvid big.mp4 small.mp4"; desc = "Shrink with default CRF (30)"; }
    { cmd = "shrinkvid big.mp4 small.mp4 23"; desc = "Higher quality (lower CRF)"; }
  ];
  fish = ''
    ffmpeg -i $argv[1] -c:v libx264 -tag:v avc1 -movflags faststart -crf (test (count $argv) -ge 3; and echo $argv[3]; or echo 30) -preset superfast $argv[2]
  '';
}
