{pkgs, ...}:

{
  interactiveShellInit = ''
    set -Ux Z_CMD "j"
    set -Ux nvm_default_version lts
    set -Ux SSH_AUTH_SOCK ~/.1password/agent.sock
    ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
  '';
}
