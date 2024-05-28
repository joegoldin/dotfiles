# zellij aliases
function ze
    zellij $argv
end

# zellij attach [container]
function za
    zellij attach "$argv"
end

# zellij run [command]
function zr
    zellij run --name "$argv" -- fish -c "$argv"
end

# zellij run floating [command]
function zrf
    zellij run --name "$argv" --floating -- fish -c "$argv"
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
