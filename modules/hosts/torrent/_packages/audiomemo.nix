_: {
  launchd.agents.audiomemo.config.EnvironmentVariables.AUDIOMEMO_MAC_HOTKEY = "F18";
  programs.audiomemo = {
    desktop = {
      enable = true;
      autoStart = true;
    };
    settings = {
      desktop = {
        dictation_mic = "mic";
        dictation_group = "combo";
        meeting_device = "combo";
      };
      record.device = "mic";
      devices = {
        mic = "MacBook Pro Microphone";
        speakers = "system-audio";
      };
      device_groups.combo = [
        "mic"
        "speakers"
      ];
    };
  };
}
