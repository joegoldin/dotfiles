if status is-interactive
    abbr -a ls "ls -la"
    abbr -a lst "ls -lath"
    abbr -a awslogin "aws sso login"

    function mkdir; command mkdir -p $argv; end
    function rm; command rm -i $argv; end
    function cp; command cp -i $argv; end
    function mv; command mv -i $argv; end
    function k; command kubectl $argv; end
    function gcm; command npx commitgpt -c $argv; end
    function cargowatch; cargo watch -cx "run --release" $argv; end
end

if begin; test -n "$CODESPACES"; and $CODESPACES; end
    set -xg SHELL "/usr/bin/fish"
end

function fish_greeting
    echo "🐟"
end

# PATH
if test -e /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end
if test -e ~/.cargo/bin
    fish_add_path ~/.cargo/bin
end
if test -e ~/.cache/rebar3/bin
    fish_add_path ~/.cache/rebar3/bin
end

# ENV
set -Ux LANG en_US.UTF-8
set -Ux nvm_default_version lts
set -Ux Z_CMD "j"
set -Ux REACT_EDITOR cursor
set -Ux EDITOR cursor
set -Ux GOPATH ~/go
fish_add_path $GOPATH/bin

# thefuck
if command -v thefuck &> /dev/null; thefuck --alias | source; end

# Starship
if command -v starship &> /dev/null; starship init fish | source; end

# Fisher plugins
if ! test -e ~/.config/fish/.fisherinstalled
    touch ~/.config/fish/.fisherinstalled
    curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
    if ! test $status -eq 0
        rm -rf ~/.config/fish/.fisherinstalled
    else
        cat .config/fish/fish_plugins | fisher install
    end
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f ~/miniconda/bin/conda
    eval ~/miniconda/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<
fish_add_path ~/miniconda/bin

# cargo
if test -f ~/.cargo/env.fish
    source ~/.cargo/env.fish
end
