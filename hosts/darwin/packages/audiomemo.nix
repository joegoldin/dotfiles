_: {
  # avfoundation device names; merged with the common audiomemo settings in
  # hosts/common/home/packages/audiomemo.nix.
  programs.audiomemo.settings = {
    record.device = "mic";
    devices.mic = "MacBook Pro Microphone";
  };
}
