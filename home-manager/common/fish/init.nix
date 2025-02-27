{pkgs, ...}: {
  interactiveShellInit = ''
    set -Ux Z_CMD "j"
    set -Ux nvm_default_version lts
    set -Ux sponge_delay 5

    direnv hook fish | source

    fish_add_path $HOME/.cargo/bin

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
  '';
}
