{
  config,
  lib,
  pkgs,
  ...
}:
{
  # KWin caches the actions for plasma-manager-commands.desktop. Registering
  # an action name on that cached component can grab the key without a launcher.
  # A dedicated entry binds the key to a real Exec. The stable launcher path
  # also lets a cached desktop entry pick up the new binary on every switch.
  xdg.dataFile = {
    "audiomemo/quick-scribe" = {
      executable = true;
      text = ''
        #!${pkgs.runtimeShell}
        exec ${config.programs.audiomemo.package}/bin/audiomemo dictate toggle
      '';
    };
    "kglobalaccel/audiomemo-quick-scribe.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Quick Scribe
      Exec="${config.xdg.dataHome}/audiomemo/quick-scribe"
      Terminal=false
      StartupNotify=false
      X-KDE-Shortcuts=Meta+G
    '';

    "audiomemo/quick-scribe-both" = {
      executable = true;
      text = ''
        #!${pkgs.runtimeShell}
        exec ${config.programs.audiomemo.package}/bin/audiomemo dictate toggle --both
      '';
    };
    "kglobalaccel/audiomemo-quick-scribe-both.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Quick Scribe (Us and Them)
      Exec="${config.xdg.dataHome}/audiomemo/quick-scribe-both"
      Terminal=false
      StartupNotify=false
      X-KDE-Shortcuts=Meta+Alt+G
    '';
  };

  home.activation.applyQuickScribeShortcut =
    lib.hm.dag.entryAfter
      [
        "applyPlasmaManager"
        "linkGeneration"
      ]
      ''
        (
          export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
          export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
          bus=${pkgs.systemd}/bin/busctl
          if [[ -S "$XDG_RUNTIME_DIR/bus" ]] && [[ $("$bus" --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus NameHasOwner s org.kde.kglobalaccel) == "b true" ]]; then
            accel=("$bus" --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel)
            register() {
              local component=$1 title=$2 key=$3
              local action=(4 "$component" _launch "$title" "$title")
              run "''${accel[@]}" doRegister as "''${action[@]}"
              # SetPresent | NoAutoloading: activate the real launcher even when
              # the compositor has not rescanned the new desktop entry yet.
              run "''${accel[@]}" setShortcut asaiu "''${action[@]}" 1 "$key" 6
            }
            run "''${accel[@]}" setForeignShortcut asai 4 kwin 'Grid View' KWin 'Toggle Grid View' 0
            run "''${accel[@]}" setForeignShortcut asai 4 plasma-manager-commands.desktop audiomemo-dictate 'Plasma Manager' 'Toggle Quick Scribe' 0
            register audiomemo-quick-scribe.desktop 'Quick Scribe' 268435527 # Qt::META | Qt::Key_G
            register audiomemo-quick-scribe-both.desktop 'Quick Scribe (Us and Them)' 402653255 # Qt::META | Qt::ALT | Qt::Key_G
          fi
        )
      '';

  programs = {
    audiomemo = {
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
