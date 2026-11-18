{ config, ... }:
{
  programs = {
    plasma.hotkeys.commands.audiomemo-dictate = {
      name = "Toggle Quick Scribe";
      key = "Meta+G";
      command = "${config.programs.audiomemo.package}/bin/audiomemo dictate toggle";
    };
    audiomemo = {
      desktop = {
        enable = true;
        autoStart = true;
      };
      settings = {
        desktop = {
          dictation_mic = "mic";
          meeting_device = "combo";
        };
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
    };
  };
}
