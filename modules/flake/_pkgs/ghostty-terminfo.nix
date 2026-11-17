{ runCommand, ncurses }:
runCommand "ghostty-terminfo"
  {
    nativeBuildInputs = [ ncurses ];
  }
  ''
    # ncurses calls this entry "ghostty"; Ghostty sets TERM=xterm-ghostty.
    infocmp -x -A ${ncurses}/share/terminfo ghostty \
      | sed 's/^ghostty|/xterm-ghostty|ghostty|/' > ghostty.terminfo
    mkdir -p "$out/share/terminfo"
    tic -x -o "$out/share/terminfo" ghostty.terminfo

    infocmp -x -A "$out/share/terminfo" xterm-ghostty > /dev/null
    infocmp -x -A "$out/share/terminfo" ghostty > /dev/null
  ''
