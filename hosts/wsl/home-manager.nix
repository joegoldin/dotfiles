{ ... }:
{
  imports = [
    ../common/home
    ./packages.nix
  ];

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
  };

  home.shellAliases = {
    ssh = "ssh.exe";
    ssh-add = "ssh-add.exe";
    op = "op.exe";
  };

  programs = {
    git.settings = {
      gpg.ssh.program = "op-ssh-sign-wsl";
      core.sshCommand = "ssh.exe";
    };
  };

  services = {
    # lorri for nix-shell
    lorri.enable = true;

    gnome-keyring.enable = true;
  };
}
