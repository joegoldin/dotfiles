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
if test -e /home/codespace/.cargo/bin
    fish_add_path /home/codespace/.cargo/bin
end
if test -e /home/codespace/.cache/rebar3/bin
    fish_add_path /home/codespace/.cache/rebar3/bin
end
if test -e "/Applications/Sublime Text.app/Contents/SharedSupport/bin"
    fish_add_path "/Applications/Sublime Text.app/Contents/SharedSupport/bin"
    set -Ux EDITOR subl
end

# ENV
set -Ux LANG en_US.UTF-8
set -Ux nvm_default_version lts
set -Ux Z_CMD "j"

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
        fisher install danhper/fish-ssh-agent
        fisher install jethrokuan/z
        fisher install jorgebucaran/autopair.fish
        fisher install nickeb96/puffer-fish
        fisher install halostatue/fish-docker
        fisher install halostatue/fish-elixir
        fisher install eth-p/fish-plugin-sudo
        fisher install halostatue/fish-rust
        fisher install halostatue/fish-go
        fisher install rstacruz/fish-asdf
    end
end

# Codespace specific stuff I didn't want to put above :shrug:
if test -e /home/codespace
    function copilot_what-the-shell
        set TMPFILE (mktemp)
        function remove_tmpfile --on-event fish_exit
            rm -f $TMPFILE
        end
        if /home/codespace/nvm/current/bin/github-copilot-cli what-the-shell $argv --shellout $TMPFILE
            if test -e "$TMPFILE"
                set FIXED_CMD (cat $TMPFILE)
                eval $FIXED_CMD
            else
                echo "Apologies! Extracting command failed"
            end
        else
            return 1
        end
    end

    function copilot_git-assist
        set TMPFILE (mktemp)
        function remove_tmpfile --on-event fish_exit
            rm -f $TMPFILE
        end
        if /home/codespace/nvm/current/bin/github-copilot-cli git-assist $argv --shellout $TMPFILE
            if test -e "$TMPFILE"
                set FIXED_CMD (cat $TMPFILE)
                eval $FIXED_CMD
            else
                echo "Apologies! Extracting command failed"
            end
        else
            return 1
        end
    end

    function copilot_gh-assist
        set TMPFILE (mktemp)
        function remove_tmpfile --on-event fish_exit
            rm -f $TMPFILE
        end
        if /home/codespace/nvm/current/bin/github-copilot-cli gh-assist $argv --shellout $TMPFILE
            if test -e "$TMPFILE"
                set FIXED_CMD (cat $TMPFILE)
                eval $FIXED_CMD
            else
                echo "Apologies! Extracting command failed"
            end
        else
            return 1
        end
    end
    abbr -a "git?" copilot_git-assist
    abbr -a "??" copilot_what-the-shell
    
    function optinstall
        fish /opt/install_optional_packages.fish
    end
    
    function optionalinstall
        fish /opt/install_optional_packages.fish
    end
end
