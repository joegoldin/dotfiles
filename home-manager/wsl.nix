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

  home.packages = with pkgs; [
    cursor-server-linux
  ];

  home.activation.cursor-server-linux = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Find the most recently modified directory in the cursor-server directory
    latest_dir=$(ls -td ${pkgs.cursor-server-linux}/* | head -1)
    latest_sub_dir=$(ls -td "$latest_dir"/* | head -1)
    bin_dir="$latest_sub_dir"/vscode-reh-linux-x64
    commit=$(cat "$bin_dir"/product.json | jq ".commit")
    target_dir=$(echo $HOME/.cursor-server/bin/$commit | tr -d '"')

    # exit if dir exists
    if [ -d $target_dir ]; then
      exit 0
    fi

    # Create the target directory if it does not exist
    mkdir -p $target_dir

    # Copy the contents to the home directory
    cp -r $bin_dir/* $target_dir
  '';
}
