{
  name = "pasta";
  desc = "Paste clipboard to stdout";
  usage = "pasta";
  type = "fish";
  body = ''
    if command -v pbpaste >/dev/null
        exec pbpaste
    else if command -v xclip >/dev/null
        exec xclip -selection clipboard -o
    else if test -e /tmp/clipboard
        exec cat /tmp/clipboard
    else
        echo '''
    end
  '';
}
