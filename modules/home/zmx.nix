# zmx (https://github.com/neurosnap/zmx): session persistence for terminal
# processes — tmux's attach/detach without the window management. Sessions
# survive SSH drops and terminal restarts; window management stays with the
# OS/terminal. Included via cli-packages; the bare package also ships on
# every NixOS box through modules/flake/_core-packages.nix.
_: {
  den.aspects.zmx.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zmx ];

      # Sourced at completion-load time so completions always match the
      # installed zmx (upstream-recommended setup).
      xdg.configFile."fish/completions/zmx.fish".text = ''
        if type -q zmx
          zmx completions fish | source
        end
      '';

      # Fish port of the upstream fzf session picker: Enter attaches to the
      # highlighted session, Ctrl-N (or Enter on no match) creates a session
      # named after the query, preview shows the session's scrollback.
      programs.fish.functions.zmx-select = {
        description = "Fuzzy-pick a zmx session (Enter: attach, Ctrl-N: create)";
        body = ''
          set -l display
          for line in (zmx list 2>/dev/null)
              set -l fields (string split \t -- $line)
              set -l name (string replace -r '.*name=' "" -- $fields[1])
              set -l pid (string replace -r '.*pid=' "" -- $fields[2])
              set -l clients (string replace -r '.*clients=' "" -- $fields[3])
              set -l dir (string replace -r '.*start_dir=' "" -- $fields[5])
              set -a display (printf '%-20s  pid:%-8s  clients:%-2s  %s' $name $pid $clients $dir)
          end

          set -l output (begin
              if set -q display[1]
                  printf '%s\n' $display
              end
          end | fzf \
              --print-query \
              --expect=ctrl-n \
              --height=80% \
              --reverse \
              --prompt='zmx> ' \
              --header='Enter: select | Ctrl-N: create new' \
              --preview='zmx history {1}' \
              --preview-window=right:60%:follow)
          set -l rc $status

          set -l query $output[1]
          set -l key $output[2]
          set -l selected $output[3]

          set -l session_name
          if test "$key" = ctrl-n; and test -n "$query"
              set session_name $query
          else if test $rc -eq 0; and test -n "$selected"
              set session_name (string split -f1 ' ' -- $selected)
          else if test -n "$query"
              set session_name $query
          else
              return 130
          end

          zmx attach $session_name
        '';
      };
    };
}
