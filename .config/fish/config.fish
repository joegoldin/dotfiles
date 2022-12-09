if test -e /opt/homebrew/bin; then fish_add_path /opt/homebrew/bin; end
if test -e "/Applications/Sublime Text.app/Contents/SharedSupport/bin"; then fish_add_path "/Applications/Sublime Text.app/Contents/SharedSupport/bin"; end

if test -e "/Applications/Sublime Text.app/Contents/SharedSupport/bin"; then set -Ux EDITOR subl; end
set -Ux Z_CMD "j"

starship init fish | source
