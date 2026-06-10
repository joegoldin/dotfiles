_: {
  # PulseAudio device names; merged with the common audiomemo settings in
  # hosts/common/home/packages/audiomemo.nix.
  programs.audiomemo.settings = {
    record.device = "mic";
    devices = {
      mic = "alsa_input.usb-MOTU_M2_M20000044767-00.HiFi__Mic1__source";
      speakers = "alsa_output.usb-MOTU_M2_M20000044767-00.HiFi__Line__sink.monitor";
    };
    device_groups.combo = [
      "mic"
      "speakers"
    ];
  };
}
