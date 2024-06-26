{pkgs, ...}: {
  interactiveShellInit = ''
    set -Ux Z_CMD "j"
    set -Ux nvm_default_version lts
    set -Ux sponge_delay 5

    direnv hook fish | source

    ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
  '';
}
