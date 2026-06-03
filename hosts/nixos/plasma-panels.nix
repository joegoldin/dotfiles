# hosts/nixos/plasma-panels.nix
# Panel layout for joe-desktop (desktop-specific launchers).
#
# Multi-monitor layout. Plasma screen numbering on this box (from
# `qdbus org.kde.plasmashell /PlasmaShell evaluateScript 'screenGeometry(i)'`):
#   0  2560x1440  DP-2     primary  -> full taskbar
#   1  1920x1080  DP-3     -> window list + clock
#   2  1080x1920  DP-1     -> window list + clock
#   3  1920x1080  DVI-I-1  -> window list + clock
#   4  1024x600   DVI-I-2  -> Elgato prompter, deliberately NO panel
#
# The Elgato is identified as the smallest-resolution display (no monitor
# exposes a usable model/EDID name here). It is also the highest screen index,
# so omitting it is the stable case: if the Elgato is unplugged the remaining
# screens 0-3 keep their numbers. Unplugging a lower-numbered screen would
# renumber the rest and could land a panel on the Elgato.
#
# Every task manager is pinned to its own screen (showOnlyCurrentScreen), so
# each panel only lists windows physically on that monitor.
{
  lib,
  ...
}:
let
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

  # Window list for the secondary monitors: only this screen's windows, no
  # pinned launchers. Icon-only to match the primary panel's task manager.
  windowList = {
    name = "org.kde.plasma.icontasks";
    config.General = {
      showOnlyCurrentScreen = true;
      # Left-click a grouped icon -> window previews (1) rather than cycling (0).
      groupedTaskVisualization = 1;
    };
  };

  # Minimal panel for a secondary monitor: that screen's windows + clock.
  secondaryPanel = screen: {
    inherit screen;
    location = "bottom";
    height = 38;
    alignment = "center";
    floating = false;
    widgets = [
      windowList
      clock
    ];
  };
in
{
  programs.plasma.panels = [
    # Primary monitor (DP-2, screen 0): the full taskbar.
    {
      screen = 0;
      location = "bottom";
      height = 38;
      alignment = "center";
      floating = false;
      widgets = [
        "org.kde.plasma.kicker"
        {
          name = "org.kde.plasma.icontasks";
          config.General = {
            # Left-click a grouped icon -> window previews (1) rather than cycling (0).
            groupedTaskVisualization = 1;
            # Only show windows on this monitor.
            showOnlyCurrentScreen = true;
            launchers = lib.concatStringsSep "," [
              "preferred://filemanager"
              "applications:zen.desktop"
              "applications:com.mitchellh.ghostty.desktop"
              "applications:dev.zed.Zed-Nightly.desktop"
              "applications:parsecd.desktop"
              "applications:discord.desktop"
              "applications:steam.desktop"
              "applications:Zoom.desktop"
              "applications:claude-desktop.desktop"
              "applications:obsidian.desktop"
              "applications:slack.desktop"
            ];
          };
        }
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
  ++ map secondaryPanel [
    1
    2
    3
  ];
}
