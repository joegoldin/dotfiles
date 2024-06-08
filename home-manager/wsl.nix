{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  username,
  homeDirectory,
  ...
}: {
  imports = [
    ./home.nix
  ];
  
  programs.git.extraConfig.gpg.ssh.program = "op-ssh-sign-wsl";
  programs.git.extraConfig.core.sshCommand = "ssh.exe";
  home.shellAliases = {
    ssh = "ssh.exe ";
    ssh-add = "ssh-add.exe";
    op = "op.exe";
  };
}
