{ lib, pkgs, ...}:

{
  home.packages = with pkgs; [
    cursor-server-linux
  ];

  home.activation.cursorServerLinuxInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Find the most recently modified directory in the cursor-server directory
    latest_dir=$(ls -td ${pkgs.cursor-server-linux}/* | head -1)
    latest_sub_dir=$(ls -td "$latest_dir"/* | head -1)
    bin_dir="$latest_sub_dir"/vscode-reh-linux-x64
    commit=$(cat "$bin_dir"/product.json | jq ".commit")
    target_dir=$(echo $HOME/.cursor-server/bin/$commit | tr -d '"')

    # Create the target directory if it does not exist
    mkdir -p $target_dir

    # Copy the contents to the home directory
    cp -ru $bin_dir/* $target_dir
  '';
}
