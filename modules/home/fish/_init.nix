{ pkgs, ... }:
{
  interactiveShellInit = ''
    set -Ux Z_CMD "j"
    set -Ux nvm_default_version lts
    set -Ux sponge_delay 5

    fish_add_path $HOME/.local/bin
    fish_add_path $HOME/.cargo/bin

    # Remove npm-global from PATH first, then add it at the end for lower priority
    if set -q fish_user_paths
        set -l index (contains -i $HOME/.npm-global/bin $fish_user_paths)
        if test -n "$index"
            set -e fish_user_paths[$index]
        end
        set -l npx_index (contains -i $HOME/.npm/_npx/bin $fish_user_paths)
        if test -n "$npx_index"
            set -e fish_user_paths[$npx_index]
        end
    end
    fish_add_path -a $HOME/.npm-global/bin
    fish_add_path -a $HOME/.npm/_npx/bin

    ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source

    # Custom key bindings for history expansion (replacing puffer-fish plugin)
    bind ! __expand_bang # Expands ! to previous command
    bind . __expand_lastarg # Expands !. to last argument

    # fish-refresh-prompt-on-cmd configuration
    # Refreshes prompt when entering command to show accurate time/git status

    # Time prompt customization (shown on right when command is entered)
    set -g rpoc_time_color yellow
    set -g rpoc_time_prefix 'at '
    set -g rpoc_time_prefix_color normal

    # Command duration customization (shown after long-running commands)
    set -g rpoc_cmd_duration_min_ms 3000
    set -g rpoc_cmd_duration_color yellow
    set -g rpoc_cmd_duration_prefix '⏱ took '
  '';
}
