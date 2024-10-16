{pkgs, ...}: {
  interactiveShellInit = ''
    set -Ux Z_CMD "j"
    set -Ux nvm_default_version lts
    set -Ux sponge_delay 5

    direnv hook fish | source

    fish_add_path $HOME/.cargo/bin

    ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source
  '';
}
