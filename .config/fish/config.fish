if status is-interactive
    abbr -a ls "ls -la"
    abbr -a lst "ls -lath"
    abbr -a awslogin "aws sso login"

    function mkdir; command mkdir -p $argv; end
    function rm; command rm -i $argv; end
    function cp; command cp -i $argv; end
    function mv; command mv -i $argv; end
end

function fish_greeting
    echo "🐟"
end

# ENV
set -Ux LANG en_US.UTF-8
set -Ux nvm_default_version lts
set -Ux Z_CMD "j"
set -Ux REACT_EDITOR cursor
set -Ux EDITOR cursor

