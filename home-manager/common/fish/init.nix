{
  pkgs,
  config,
  ...
}: let
  # Import custom packages from node configuration
  customNodePackages = import ../node/custom-node-packages.nix {
    inherit pkgs config;
    lib = pkgs.lib;
    nodejs_22 = pkgs.unstable.nodejs_22;
    unstable = pkgs.unstable or pkgs;
  };

  # Generate fish env variable settings for node packages
  nodeEnvVars = pkgs.lib.concatStringsSep "\n" (pkgs.lib.concatMap (
      pkg:
        if pkg ? env
        then
          pkgs.lib.mapAttrsToList (
            name: value: ''set -Ux ${name} "${value}"''
          )
          pkg.env
        else []
    )
    customNodePackages.directNpmPackages);
in {
  interactiveShellInit = ''
    set -Ux Z_CMD "j"
    set -Ux nvm_default_version lts
    set -Ux sponge_delay 5

    set -Ux PLAYWRIGHT_BROWSERS_PATH ${pkgs.playwright-driver.browsers}
    set -Ux PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true

    direnv hook fish | source

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
    set -Ux NODE_PATH "${config.home.profileDirectory}/lib/node_modules:$HOME/.npm-global/lib/node_modules"
    set -Ux NPM_CONFIG_PREFIX "$HOME/.npm-global"

    # Set Node package environment variables
    # ${nodeEnvVars}

    # from https://github.com/CGamesPlay/llm-cmd-comp/blob/main/share/llm-cmd-comp.fish
    bind \e\\ __llm_cmdcomp

    function __llm_cmdcomp -d "Fill in the command using an LLM"
      set __llm_oldcmd (commandline -b)
      set __llm_cursor_pos (commandline -C)
      echo # Start the program on a blank line
      set result (llm cmdcomp $__llm_oldcmd)
      if test $status -eq 0
        commandline -r $result
        echo # Move down a line to prevent fish from overwriting the program output
      end
      commandline -f repaint
    end

    ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source

    # Custom key bindings for history expansion (replacing puffer-fish plugin)
    bind ! __expand_bang # Expands ! to previous command
    bind . __expand_lastarg # Expands !. to last argument
  '';
}
