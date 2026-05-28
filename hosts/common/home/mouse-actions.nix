{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Live config persisted from ~/.config/mouse-actions.json. Single delta vs.
  # what mouse-actions-gui writes to disk: the Overview shortcut is invoked
  # via dbus-send instead of qdbus. qdbus from qttools 6.11 SEGVs in
  # QDBusConnectionManager's destructor during exit handlers — the shortcut
  # still fires, but the non-zero exit makes mouse-actions report failure.
  configJson = builtins.replaceStrings [ "@DBUS_SEND@" ] [ "${pkgs.dbus}/bin/dbus-send" ] (
    builtins.readFile ./mouse-actions.json
  );

  configFile = pkgs.writeText "mouse-actions.json" configJson;

  # Daemon = patched CLI (owns the grabbed mouse, drag-shift logic baked in).
  # GUI AppImage stays installed via home.packages for config editing only.
  mouseActionsDaemon = "${pkgs.mouse-actions-patched}/bin/mouse-actions";

  # KDE tray toggle: click to start/stop mouse-actions.service, icon shows state.
  # Qt's QSystemTrayIcon bridges to KStatusNotifierItem on Plasma 6.
  mouseActionsTray =
    pkgs.writers.writePython3Bin "mouse-actions-tray"
      {
        libraries = [ pkgs.python3Packages.pyside6 ];
        flakeIgnore = [
          "E501"
          "E402"
          "E302"
          "E305"
          "W503"
        ];
      }
      ''
        import subprocess
        import sys
        from PySide6.QtWidgets import QApplication, QSystemTrayIcon, QMenu
        from PySide6.QtGui import QIcon, QPixmap, QPainter, QColor, QPen
        from PySide6.QtCore import QTimer, Qt

        SERVICE = "mouse-actions.service"

        def is_active() -> bool:
            r = subprocess.run(
                ["systemctl", "--user", "is-active", SERVICE],
                capture_output=True, text=True,
            )
            return r.stdout.strip() == "active"

        def make_icon(active: bool) -> QIcon:
            size = 64
            px = QPixmap(size, size)
            px.fill(Qt.transparent)
            p = QPainter(px)
            p.setRenderHint(QPainter.Antialiasing, True)
            fill = QColor("#3daee9") if active else QColor("#555555")
            p.setBrush(fill)
            p.setPen(QPen(fill.darker(150), 3))
            p.drawEllipse(8, 8, size - 16, size - 16)
            p.setPen(QPen(QColor("white"), 4))
            p.setBrush(Qt.NoBrush)
            if active:
                p.drawLine(22, 32, 30, 42)
                p.drawLine(30, 42, 46, 22)
            else:
                p.drawLine(22, 22, 42, 42)
                p.drawLine(42, 22, 22, 42)
            p.end()
            return QIcon(px)

        def main():
            app = QApplication(sys.argv)
            app.setQuitOnLastWindowClosed(False)

            tray = QSystemTrayIcon()
            menu = QMenu()
            toggle_action = menu.addAction("Toggle")
            menu.addSeparator()
            quit_action = menu.addAction("Quit tray")
            tray.setContextMenu(menu)

            def refresh():
                active = is_active()
                tray.setIcon(make_icon(active))
                tray.setToolTip(f"mouse-actions: {'on' if active else 'off'}")
                toggle_action.setText("Disable" if active else "Enable")

            def toggle():
                action = "stop" if is_active() else "start"
                subprocess.run(["systemctl", "--user", action, SERVICE], check=False)
                QTimer.singleShot(400, refresh)

            def on_activate(reason):
                if reason == QSystemTrayIcon.Trigger:
                    toggle()

            tray.activated.connect(on_activate)
            toggle_action.triggered.connect(toggle)
            quit_action.triggered.connect(app.quit)

            refresh()
            timer = QTimer()
            timer.timeout.connect(refresh)
            timer.start(5000)

            tray.show()
            sys.exit(app.exec())

        if __name__ == "__main__":
            main()
      '';
in
{
  home.packages = with pkgs; [
    mouse-actions
    # nixpkgs' mouse-actions-gui is marked broken because Tauri v1 needs
    # webkit2gtk-4.0, which was removed from nixpkgs. Use upstream's AppImage
    # (which bundles webkit2gtk-4.0) until upstream migrates to Tauri v2.
    mouse-actions-gui-appimage
    xdotool
    mouseActionsTray
  ];

  # Copy the config into place. Each switch overwrites on-disk edits with the
  # in-tree config — the in-tree JSON is the source of truth. Re-sync by
  # copying ~/.config/mouse-actions.json back to this directory when you've
  # made edits in the GUI you want to keep.
  home.activation.mouseActionsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.xdg.configHome}
    rm -f ${config.xdg.configHome}/mouse-actions.json
    install -m644 ${configFile} ${config.xdg.configHome}/mouse-actions.json
  '';

  systemd.user.services.mouse-actions = {
    Unit = {
      Description = "mouse-actions gesture daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${mouseActionsDaemon} start";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.mouse-actions-tray = {
    Unit = {
      Description = "mouse-actions tray toggle";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${mouseActionsTray}/bin/mouse-actions-tray";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
