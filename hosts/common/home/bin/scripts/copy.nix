{
  name = "copy";
  desc = "Copy stdin to clipboard";
  usage = "echo hi | copy";
  type = "fish";
  body = ''
    if command -v pbcopy >/dev/null
        exec pbcopy
    else if command -v wl-copy >/dev/null
        exec wl-copy
    else if command -v xclip >/dev/null
        exec xclip -selection clipboard
    else if command -v putclip >/dev/null
        exec putclip
    else
        rm -f /tmp/clipboard 2>/dev/null
        if test (count $argv) -eq 0
            cat >/tmp/clipboard
        else
            cat $argv[1] >/tmp/clipboard
        end
    end
  '';
}
