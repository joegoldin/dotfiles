{ lib, ... }:
let
  ghosttySettings = import ../../home/ghostty/_settings.nix { inherit lib; };
  macosSettings = ghosttySettings.baseSettings // {
    command = "/etc/profiles/per-user/joe/bin/fish";
    font-size = 13;
    window-subtitle = "working-directory";
    shell-integration-features = "sudo,title,ssh-env,ssh-terminfo";
    mouse-shift-capture = true;
  };
in
{
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    text = ghosttySettings.toGhosttyConfig macosSettings;
  };
}
