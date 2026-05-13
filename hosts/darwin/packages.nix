{ pkgs, ... }:
{
  home.packages = with pkgs; [
    shopt-script
    iterm2-terminal-integration
  ];

  # avfoundation device names; merged with the common audiomemo settings in
  # hosts/common/home/packages.nix.
  programs.audiomemo.settings = {
    record.device = "mic";
    devices.mic = "MacBook Pro Microphone";
  };
}
