{
  pkgs,
  username,
  ...
}:
let
  hyprwhspr = pkgs.callPackage ../common/system/pkgs/hyprwhspr { };

  # Declarative config — only include overrides, hyprwhspr uses sparse storage
  settings = {
    primary_shortcut = "SUPER+ALT+D";
    cancel_shortcut = "ESCAPE";
    recording_mode = "auto";
    transcription_backend = "pywhispercpp";
    model = "base.en";
    language = "en";
    filter_filler_words = true;
    audio_feedback = true;
    audio_ducking = false;
    mic_osd_enabled = true;
    audio_device_name = "default";
  };

  configFile = pkgs.writeText "hyprwhspr-config.json" (builtins.toJSON settings);
in
{
  home-manager.users.${username} = {
    xdg.configFile."hyprwhspr/config.json".source = configFile;
  };

  systemd.user.services.hyprwhspr = {
    description = "hyprwhspr speech-to-text";
    documentation = [ "https://github.com/goodroot/hyprwhspr" ];
    partOf = [ "graphical-session.target" ];
    after = [
      "graphical-session.target"
      "pipewire.service"
      "wireplumber.service"
    ];
    wantedBy = [ "graphical-session.target" ];
    wants = [
      "pipewire.service"
      "wireplumber.service"
    ];

    serviceConfig = {
      Type = "simple";
      ExecStartPre = "${hyprwhspr}/bin/hyprwhspr model download ${settings.model}";
      ExecStart = "${hyprwhspr}/bin/hyprwhspr";
      ExecStopPost = "-${pkgs.procps}/bin/pkill -9 -f hyprwhspr-virtual-keyboard";
      Environment = [
        "PYTHONUNBUFFERED=1"
      ];
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # ydotool daemon is required for text injection
  programs.ydotool.enable = true;
}
