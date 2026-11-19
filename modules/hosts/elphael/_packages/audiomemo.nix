{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Updating kglobalshortcutsrc does not reassign a shortcut already held by
  # the running KWin. At login Plasma reads the generated files itself.
  home.activation.applyQuickScribeShortcut = lib.hm.dag.entryAfter [ "applyPlasmaManager" ] ''
    (
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
      export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
      bus=${pkgs.systemd}/bin/busctl
      if [[ -S "$XDG_RUNTIME_DIR/bus" ]] && [[ $("$bus" --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus NameHasOwner s org.kde.kglobalaccel) == "b true" ]]; then
        accel=("$bus" --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel)
        action=(4 plasma-manager-commands.desktop audiomemo-dictate 'Plasma Manager' 'Toggle Quick Scribe')
        key=268435527 # Qt::META | Qt::Key_G
        run "''${accel[@]}" doRegister as "''${action[@]}"
        run "''${accel[@]}" setForeignShortcut asai 4 kwin 'Grid View' KWin 'Toggle Grid View' 0
        run "''${accel[@]}" setForeignShortcut asai "''${action[@]}" 1 "$key"
      fi
    )
  '';

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
