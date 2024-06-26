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
    ../common/cursor-server-linux.nix
  ];

  home.packages =
    (import ../common/packages.nix {inherit pkgs;}).home.packages
    ++ (with pkgs; [
      # wsl only packages
    ]);

  # lorri for nix-shell
  services.lorri.enable = true;

  programs.git.extraConfig.gpg.ssh.program = "op-ssh-sign-wsl";
  programs.git.extraConfig.core.sshCommand = "ssh.exe";
  home.shellAliases = {
    ssh = "ssh.exe";
    ssh-add = "ssh-add.exe";
    op = "op.exe";
  };
}
