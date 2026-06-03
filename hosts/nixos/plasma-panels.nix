# hosts/nixos/plasma-panels.nix
# Panel layout for joe-desktop.
#
# Multi-monitor layout. Plasma screen numbering on this box (from
# `qdbus org.kde.plasmashell /PlasmaShell evaluateScript 'screenGeometry(i)'`):
#   0  2560x1440  DP-2     primary    -> full taskbar
#   1  1920x1080  DP-3     landscape  -> taskbar: files, zen, ghostty
#   2  1080x1920  DP-1     vertical   -> taskbar: files, ghostty, discord, slack
#   3  1920x1080  DVI-I-1  landscape  -> taskbar: files, zen, ghostty
#   4  1024x600   DVI-I-2  Elgato prompter, deliberately NO panel
#
# The Elgato is identified as the smallest-resolution display (no monitor
# exposes a usable model/EDID name here). It is also the highest screen index,
# so omitting it is the stable case: if the Elgato is unplugged the remaining
# screens 0-3 keep their numbers. Unplugging a lower-numbered screen would
# renumber the rest and could land a panel on the Elgato.
#
# Every task manager is pinned to its own screen (showOnlyCurrentScreen), so
# each panel only lists windows physically on that monitor. New windows open on
# the monitor under the cursor (kwinrc Windows.ActiveMouseScreen, set in
# plasma.nix), so launching an app from a panel opens it on that panel's screen.
{
  lib,
  ...
}:
let
  # Launcher URLs, referenced per-screen below.
  apps = {
    files = "preferred://filemanager";
    zen = "applications:zen.desktop";
    ghostty = "applications:com.mitchellh.ghostty.desktop";
    zed = "applications:dev.zed.Zed-Nightly.desktop";
    parsec = "applications:parsecd.desktop";
    discord = "applications:discord.desktop";
    steam = "applications:steam.desktop";
    zoom = "applications:Zoom.desktop";
    claude = "applications:claude-desktop.desktop";
    obsidian = "applications:obsidian.desktop";
    slack = "applications:slack.desktop";
  };

  # Clock — identical on every panel.
  clock = {
    digitalClock = {
      date.format = {
        custom = "ddd MMM d";
      };
      time.showSeconds = "always";
      font = {
        family = "Noto Sans";
        weight = 400;
      };
    };
  };

  # The icon-only task manager. It is configured entirely from extraSettings
  # (below), NOT here, so its config groups exist but stay empty until then.
  taskbar = "org.kde.plasma.icontasks";

  # plasma-manager's `screen` option is broken on Plasma 6: it emits the
  # uninterpolated key `lastScreen[$i]`, so every panel lands on screen 0.
  #
  # We instead drive everything from extraSettings, raw layout JS that runs
  # after the widgets are added. Order matters:
  #   1. `panel.screen = N` is the only call that relocates a panel and persists
  #      across a plasmashell restart.
  #   2. Relocating a panel drops applet config written during addWidget(), so
  #      the task manager must be configured *after* the move.
  #   3. reloadConfig() forces the applet to pick the values up; launchers
  #      written without it are silently dropped by the applet's async init.
  configureTaskbar =
    { screen, launchers }:
    ''
      panel.screen = ${toString screen};
      var it = panelWidgets["${taskbar}"];
      it.currentConfigGroup = ["General"];
      it.writeConfig("showOnlyCurrentScreen", true);
      it.writeConfig("groupedTaskVisualization", 1);
      it.writeConfig("launchers", "${lib.concatStringsSep "," launchers}");
      it.reloadConfig();
    '';

  # Secondary monitor: pinned apps + own-screen window list + clock.
  secondaryPanel =
    { screen, launchers }:
    {
      location = "bottom";
      height = 38;
      alignment = "center";
      floating = false;
      extraSettings = configureTaskbar { inherit screen launchers; };
      widgets = [
        taskbar
        clock
      ];
    };
in
{
  programs.plasma.panels = [
    # Primary monitor (DP-2, screen 0): the full taskbar.
    {
      location = "bottom";
      height = 38;
      alignment = "center";
      floating = false;
      extraSettings = configureTaskbar {
        screen = 0;
        launchers = [
          apps.files
          apps.zen
          apps.ghostty
          apps.zed
          apps.parsec
          apps.discord
          apps.steam
          apps.zoom
          apps.claude
          apps.obsidian
          apps.slack
        ];
      };
      widgets = [
        "org.kde.plasma.kicker"
        taskbar
        "org.kde.plasma.marginsseparator"
        "org.kde.netspeedWidget"
        "org.kde.plasma.systemmonitor.cpucore"
        "org.kde.plasma.systemmonitor.memory"
        "org.kde.plasma.marginsseparator"
        {
          name = "org.kde.plasma.systemtray";
          config.General = {
            extraItems = lib.concatStringsSep "," [
              "org.kde.plasma.cameraindicator"
              "org.kde.plasma.manage-inputmethod"
              "org.kde.plasma.clipboard"
              "org.kde.plasma.bluetooth"
              "org.kde.plasma.keyboardlayout"
              "org.kde.plasma.devicenotifier"
              "org.kde.plasma.mediacontroller"
              "org.kde.plasma.notifications"
              "org.kde.kscreen"
              "org.kde.plasma.brightness"
              "org.kde.plasma.networkmanagement"
              "org.kde.plasma.battery"
              "org.kde.plasma.volume"
              "org.kde.plasma.printmanager"
              "org.kde.plasma.keyboardindicator"
              "org.kde.plasma.weather"
            ];
            knownItems = lib.concatStringsSep "," [
              "org.kde.plasma.cameraindicator"
              "org.kde.plasma.manage-inputmethod"
              "org.kde.plasma.clipboard"
              "org.kde.plasma.bluetooth"
              "org.kde.plasma.keyboardlayout"
              "org.kde.plasma.devicenotifier"
              "org.kde.plasma.mediacontroller"
              "org.kde.plasma.notifications"
              "org.kde.kscreen"
              "org.kde.plasma.brightness"
              "org.kde.plasma.networkmanagement"
              "org.kde.plasma.battery"
              "org.kde.plasma.volume"
              "org.kde.plasma.printmanager"
              "org.kde.plasma.keyboardindicator"
              "org.kde.plasma.weather"
            ];
          };
        }
        clock
        # "View desktop" button.
        "org.kde.plasma.minimizeall"
      ];
    }
  ]
  ++ [
    (secondaryPanel {
      screen = 1;
      launchers = [
        apps.files
        apps.zen
        apps.ghostty
      ];
    })
    # Vertical monitor.
    (secondaryPanel {
      screen = 2;
      launchers = [
        apps.files
        apps.ghostty
        apps.discord
        apps.slack
      ];
    })
    (secondaryPanel {
      screen = 3;
      launchers = [
        apps.files
        apps.zen
        apps.ghostty
      ];
    })
  ];
}
