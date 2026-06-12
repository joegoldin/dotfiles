_: {
  # avfoundation device names; merged with the common audiomemo settings in
  # modules/home/_hm/packages/audiomemo.nix.
  programs.audiomemo.settings = {
    record.device = "mic";
    devices.mic = "MacBook Pro Microphone";
  };
}
