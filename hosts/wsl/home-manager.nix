{pkgs, ...}: {
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
    gpg.enable = true;
  };

  services = {
    # lorri for nix-shell
    lorri.enable = true;

    # gnupg gpg stuff
    gnome-keyring.enable = true;
    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-curses;
    };
  };
}
