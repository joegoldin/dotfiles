{pkgs, ...}:

{
  interactiveShellInit = ''
    set -Ux Z_CMD "j"
    set -Ux nvm_default_version lts
    ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
  '';
}
