{
  lib,
  pkgs,
  username,
  useremail,
  ...
}: {
  # `programs.git` will generate the config file: ~/.config/git/config
  # to make git use this config file, `~/.gitconfig` should not exist!
  #
  #    https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    rm -f ~/.gitconfig
  '';

  programs.git = {
    enable = true;
    lfs.enable = true;

    # TODO replace with your own name & email
    userName = "joegoldin";
    userEmail = "joe@joegold.in";

    # includes = [
    #   {
    #     # use diffrent email & name for work
    #     path = "~/work/.gitconfig";
    #     condition = "gitdir:~/work/";
    #   }
    # ];

    extraConfig = {
      init.defaultBranch = lib.mkDefault "main";
      push.autoSetupRemote = lib.mkDefault true;
      pull.rebase = lib.mkDefault true;
      rerere.enabled = lib.mkDefault true;

      column.ui = lib.mkDefault "auto";
      branch.sort = lib.mkDefault "-committerdate";
      tag.sort = lib.mkDefault "version:refname";

      diff.algorithm = lib.mkDefault "histogram";
      diff.colorMoved = lib.mkDefault "plain";
      diff.mnemonicPrefix = lib.mkDefault true;
      diff.renames = lib.mkDefault true;

      help.autocorrect = lib.mkDefault "prompt";
      commit.verbose = lib.mkDefault true;
    };

    delta = {
      enable = true;
      options = {
        features = "side-by-side";
      };
    };

    aliases = {
      # common aliases
      br = "branch";
      co = "checkout";
      st = "status";
      ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
      ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";
      cm = "commit -m";
      ca = "commit -am";
      dc = "diff --cached";
      # amend = "commit --amend -m";

      # aliases for submodule
      update = "submodule update --init --recursive";
      foreach = "submodule foreach";

      # git-stack aliases
      sync = "stack sync";
      ss = "stack sync";
      next = "stack next";
      prev = "stack prev";
      reword = "stack reword";
      amend = "stack amend";
      run = "stack run";
      restack = "stack --repair";
      rs = "stack --repair";
      pushstack = "stack --push";
      ps = "stack --push";
      rebasestack = "stack --rebase";
      rbs = "stack --rebase";
    };
  };
}
