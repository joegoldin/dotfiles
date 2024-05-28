if status is-interactive
    abbr -a ls "exa -la -s modified --header"
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
        fisher update
    end
end

# zellij aliases
alias ze='zellij'

# zellij attach [container]
function za
    zellij attach "$argv"
end

# zellij run [command]
function zr
    zellij run --name "$argv" -- zsh -ic "$argv"
end

# zellij run floating [command]
function zrf
    zellij run --name "$argv" --floating -- zsh -ic "$argv"
end

# zellij edit file [file]
function zed
    zellij edit $argv
end

# zellij attach
function zs
    set sessions (zellij list-sessions --no-formatting | awk '{printf "\033[1;36m%-20s\033[0m %s\n", $1, $3}')
    set selected_session (echo "$sessions" | fzf --height (set -q FZF_TMUX_HEIGHT; and echo $FZF_TMUX_HEIGHT; or echo 20%) --ansi)
    if test -n "$selected_session"
        za (echo $selected_session | awk '{print $1}')
    end
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f ~/miniconda3/bin/conda
    eval ~/miniconda3/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<
fish_add_path ~/miniconda3/bin
