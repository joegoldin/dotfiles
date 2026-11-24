{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  owly = lib.getExe osConfig.services.owly.package;
  systemd = "${pkgs.systemd}/bin";
  panelTool = pkgs.writeScript "owly-panel" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.replaceStrings
      [ "@owly@" "@systemctl@" "@busctl@" ]
      [
        owly
        "${systemd}/systemctl"
        "${systemd}/busctl"
      ]
      (builtins.readFile ./panel.py)
    }
  '';
  confirm = pkgs.writeShellScript "owly-confirm" ''
    exec ${lib.getExe pkgs.zenity} --question --no-markup --default-cancel \
      --title='Incoming AirDrop' --ok-label='Accept' --cancel-label='Decline' --text="$1"
  '';
  widget = pkgs.callPackage ./plasma-widget.nix {
    inherit panelTool;
    systemdRun = "${systemd}/systemd-run";
  };
in
{
  home.packages = [ widget ];

  systemd.user.services.owly-receive = {
    Unit = {
      Description = "Receive AirDrop files with explicit per-transfer approval";
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    # No WantedBy: the panel opens the receive window, not login.
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Downloads";
      ExecStart = "${owly} receive --dir %h/Downloads --confirm-with ${confirm}";
      RuntimeMaxSec = "10min";
      Restart = "no";
      NoNewPrivileges = true;
      UMask = "0077";
    };
  };
}
