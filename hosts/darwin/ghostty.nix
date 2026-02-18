{ lib, ... }:
let
  ghosttySettings = import ../common/home/ghostty-settings.nix { inherit lib; };
  macosSettings = ghosttySettings.baseSettings // {
    command = "/etc/profiles/per-user/joe/bin/fish";
  };
in
{
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    text = ghosttySettings.toGhosttyConfig macosSettings;
  };
}
