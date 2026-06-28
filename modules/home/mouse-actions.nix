{ ... }:
{
  den.aspects.mouse-actions.homeManager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # Gesture bindings (nix is source of truth). Overview uses dbus-send instead
      # of qdbus because qttools 6.11 SEGVs in QDBusConnectionManager's destructor
      # during exit handlers; the shortcut still fires, but the non-zero exit
      # makes mouse-actions report failure.
      mouseActionsConfig = {
        shape_button = "Right";
        bindings = [
          {
            comment = "Overview";
            event = {
              button = "Right";
              event_type = "Shape";
              shapes_xy = [
                [
                  0
                  41
                  5
                  46
                  5
                  49
                  8
                  51
                  10
                  56
                  21
                  67
                  26
                  74
                  36
                  85
                  36
                  90
                  51
                  105
                  62
                  121
                  72
                  136
                  82
                  151
                  92
                  167
                  108
                  182
                  113
                  192
                  118
                  197
                  133
                  218
                  149
                  238
                  154
                  244
                  169
                  269
                  179
                  290
                  195
                  305
                  200
                  321
                  215
                  336
                  221
                  351
                  236
                  367
                  246
                  382
                  251
                  392
                  256
                  397
                  272
                  418
                  277
                  428
                  282
                  438
                  292
                  449
                  297
                  459
                  303
                  469
                  313
                  479
                  318
                  490
                  328
                  495
                  333
                  505
                  338
                  510
                  344
                  521
                  354
                  526
                  359
                  536
                  369
                  541
                  374
                  551
                  379
                  556
                  390
                  562
                  395
                  567
                  405
                  577
                  410
                  582
                  415
                  587
                  421
                  592
                  431
                  597
                  436
                  603
                  441
                  603
                  451
                  608
                  456
                  613
                  462
                  618
                  467
                  623
                  469
                  623
                  479
                  628
                  485
                  633
                  490
                  633
                  495
                  636
                  500
                  636
                  505
                  641
                  510
                  641
                  513
                  646
                  518
                  646
                  523
                  651
                  528
                  651
                  533
                  656
                  538
                  656
                  541
                  659
                  546
                  659
                  549
                  659
                  554
                  659
                  559
                  664
                  564
                  664
                  567
                  664
                  569
                  664
                  574
                  669
                  579
                  669
                  582
                  669
                  587
                  669
                  590
                  669
                  592
                  669
                  597
                  669
                  600
                  669
                  605
                  669
                  608
                  669
                  610
                  669
                  610
                  667
                  615
                  667
                  618
                  667
                  623
                  662
                  628
                  656
                  631
                  656
                  636
                  654
                  636
                  649
                  638
                  644
                  644
                  641
                  649
                  636
                  654
                  631
                  654
                  628
                  656
                  623
                  662
                  618
                  662
                  613
                  667
                  608
                  672
                  603
                  672
                  597
                  677
                  592
                  682
                  582
                  687
                  574
                  692
                  569
                  692
                  564
                  697
                  554
                  703
                  549
                  708
                  544
                  713
                  533
                  713
                  528
                  718
                  523
                  723
                  513
                  728
                  503
                  733
                  497
                  733
                  487
                  738
                  482
                  744
                  472
                  749
                  467
                  754
                  456
                  759
                  446
                  764
                  436
                  764
                  431
                  769
                  421
                  774
                  410
                  779
                  400
                  785
                  390
                  790
                  379
                  795
                  374
                  800
                  364
                  805
                  354
                  810
                  344
                  815
                  338
                  821
                  328
                  821
                  318
                  826
                  308
                  831
                  297
                  841
                  277
                  846
                  267
                  851
                  256
                  856
                  246
                  862
                  236
                  867
                  226
                  872
                  215
                  877
                  210
                  882
                  200
                  887
                  190
                  892
                  179
                  903
                  169
                  908
                  159
                  913
                  154
                  918
                  144
                  923
                  133
                  928
                  123
                  933
                  113
                  938
                  103
                  944
                  92
                  949
                  87
                  954
                  77
                  959
                  67
                  964
                  56
                  969
                  51
                  974
                  41
                  979
                  31
                  985
                  26
                  990
                  15
                  995
                  10
                  1000
                  0
                ]
              ];
            };
            cmd_str = "${pkgs.dbus}/bin/dbus-send --type=method_call --dest=org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut string:Overview";
          }
        ];

        # Drag-shift: while Left button is held, Right click toggles ShiftLeft
        # so KWin sees Shift+drag → axis-snap during window moves.
        modifier_remaps = [
          {
            comment = "drag-shift: Left+Right toggles ShiftLeft for KWin axis-snap";
            while_held = {
              kind = "Mouse";
              code = "Left";
            };
            trigger = {
              kind = "Mouse";
              code = "Right";
            };
            emit = {
              kind = "Key";
              code = "ShiftLeft";
            };
            mode = "Toggle";
            release_delay_ms = 25;
          }
        ];

        # Forward + Back mouse buttons within 100 ms → KDE Overview.
        # passthrough=false swallows both buttons so the browser doesn't see
        # back/forward when you fire the chord. mouse-actions defers the first
        # press for window_ms; if the second arrives in time the chord fires
        # and the deferred press is dropped, otherwise a uinput re-injection
        # turns it back into a solo click (~100 ms perceived latency).
        chord_bindings = [
          {
            comment = "BTN_SIDE + BTN_EXTRA → Overview";
            buttons = [
              "Side"
              "Extra"
            ];
            window_ms = 100;
            cmd_str = "${pkgs.dbus}/bin/dbus-send --type=method_call --dest=org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut string:Overview";
            passthrough = false;
          }
        ];
      };

      configFile = (pkgs.formats.json { }).generate "mouse-actions.json" mouseActionsConfig;

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
            import shutil
            import subprocess
            import sys
            from PySide6.QtWidgets import QApplication, QSystemTrayIcon, QMenu
            from PySide6.QtGui import QIcon, QPixmap, QPainter, QColor, QPen
            from PySide6.QtCore import QTimer, Qt

            SERVICE = "mouse-actions.service"
            GUI_BIN = "mouse-actions-gui"

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

                base = QIcon.fromTheme("input-mouse")
                if base.isNull():
                    base = QIcon.fromTheme("preferences-desktop-mouse")
                if not base.isNull():
                    base.paint(p, 0, 0, size, size)
                else:
                    # fallback: draw a tiny mouse silhouette
                    body = QColor("#cccccc")
                    p.setBrush(body)
                    p.setPen(QPen(body.darker(150), 2))
                    p.drawRoundedRect(16, 8, 32, 44, 16, 18)
                    p.drawLine(32, 8, 32, 28)

                # status badge bottom-right (check = on, X = off)
                badge_d = 30
                pad = 2
                bx = size - badge_d - pad
                by = size - badge_d - pad
                badge_fill = QColor("#27ae60") if active else QColor("#c0392b")
                p.setBrush(badge_fill)
                p.setPen(QPen(badge_fill.darker(160), 2))
                p.drawEllipse(bx, by, badge_d, badge_d)
                p.setPen(QPen(QColor("white"), 3, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin))
                p.setBrush(Qt.NoBrush)
                if active:
                    p.drawLine(bx + 7, by + 16, bx + 13, by + 22)
                    p.drawLine(bx + 13, by + 22, bx + 23, by + 9)
                else:
                    p.drawLine(bx + 9, by + 9, bx + 21, by + 21)
                    p.drawLine(bx + 21, by + 9, bx + 9, by + 21)
                p.end()
                return QIcon(px)

            def main():
                app = QApplication(sys.argv)
                app.setQuitOnLastWindowClosed(False)

                tray = QSystemTrayIcon()
                menu = QMenu()
                toggle_action = menu.addAction("Toggle")
                gui_action = None
                if shutil.which(GUI_BIN):
                    gui_action = menu.addAction("Open mouse-actions-gui")
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

                def open_gui():
                    subprocess.Popen(
                        [GUI_BIN],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        start_new_session=True,
                    )

                tray.activated.connect(on_activate)
                toggle_action.triggered.connect(toggle)
                if gui_action is not None:
                    gui_action.triggered.connect(open_gui)
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
        # Fork built from source with Tauri v2; knows about modifier_remaps and
        # chord_bindings. Symlinks `mouse-actions-gui` so the tray's
        # shutil.which() and the CLI's `show-gui` subcommand find it.
        mouse-actions-gui-fork
        xdotool
        mouseActionsTray
      ];

      # Copy the config into place. Each switch overwrites on-disk edits with the
      # in-tree config; the in-tree JSON is the source of truth. Re-sync by
      # copying ~/.config/mouse-actions.json back to this directory when you've
      # made edits in the GUI you want to keep.
      home.activation.mouseActionsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p ${config.xdg.configHome}
        rm -f ${config.xdg.configHome}/mouse-actions.json
        install -m644 ${configFile} ${config.xdg.configHome}/mouse-actions.json
      '';

      # Always restart the daemon on switch. It exclusively grabs the pointer for
      # drag-shift / shape-gesture detection; carrying that grab across a rebuild
      # can wedge left-click + scroll (right-button events still pass through) until
      # the service is restarted. Force a clean stop/start after the config is
      # installed and systemd has reloaded the unit. Guarded so a switch outside a
      # graphical session (unit not enabled / no user bus) doesn't fail activation.
      home.activation.restartMouseActions =
        lib.hm.dag.entryAfter
          [
            "reloadSystemd"
            "mouseActionsConfig"
          ]
          ''
            if ${pkgs.systemd}/bin/systemctl --user is-enabled mouse-actions.service >/dev/null 2>&1; then
              $DRY_RUN_CMD ${pkgs.systemd}/bin/systemctl --user restart mouse-actions.service || true
            fi
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
    };
}
