if test -e /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end

if test -e "/Applications/Sublime Text.app/Contents/SharedSupport/bin"
    fish_add_path "/Applications/Sublime Text.app/Contents/SharedSupport/bin"
end

if test -e "/Applications/Sublime Text.app/Contents/SharedSupport/bin"
    set -Ux EDITOR subl
end

set -Ux Z_CMD "j"

function fish_greeting
    echo "🐟"
end

if which starship &> /dev/null; starship init fish | source; end
