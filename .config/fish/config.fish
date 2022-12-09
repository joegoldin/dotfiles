fish_add_path /opt/homebrew/bin
fish_add_path "/Applications/Sublime Text.app/Contents/SharedSupport/bin"

set -Ux EDITOR subl
set -Ux Z_CMD "j"

starship init fish | source
