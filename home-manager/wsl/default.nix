{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  username,
  homeDirectory,
  stateVersion,
  ...
}: {
  imports = [
    ../common
  ];

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
  };

  # lorri for nix-shell
  services.lorri.enable = true;

  # WSL-specific starship configuration
  # programs.starship.settings.line_break = {
  #   disabled = true;
  # };

  programs.git.settings.gpg.ssh.program = "op-ssh-sign-wsl";
  programs.git.settings.core.sshCommand = "ssh.exe";
  home.shellAliases = {
    ssh = "ssh.exe";
    ssh-add = "ssh-add.exe";
    op = "op.exe";
  };

  # gnupg gpg stuff
  services.gnome-keyring.enable = true;
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };
}
