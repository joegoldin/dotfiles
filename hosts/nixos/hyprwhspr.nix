{
  pkgs,
  ...
}:
let
  hyprwhspr = pkgs.callPackage ../common/system/pkgs/hyprwhspr { };
in
{
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
      ExecStart = "${hyprwhspr}/bin/hyprwhspr";
      ExecStopPost = "${pkgs.procps}/bin/pkill -9 -f 'hyprwhspr-virtual-keyboard' || true";
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
