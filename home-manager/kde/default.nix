{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    ../common
  ];

  programs.plasma = {
    enable = true;

    # Workspace appearance
    workspace = {
      theme = "breeze-dark";
      # Managed by superpaper
      # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/5120x2880.png";
      lookAndFeel = "org.kde.breezedark.desktop";
      clickItemTo = "select"; # Options are "select" or "open"
    };

    # Panel configuration
    panels = [
      # Main panel at the bottom
      {
        location = "bottom";
        height = 38;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.icontasks"
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
    ];

    # Shortcuts
    shortcuts = {
      kwin = {
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";
        "Switch Window Down" = "Meta+J";
        "Switch Window Left" = "Meta+H";
        "Switch Window Right" = "Meta+L";
        "Switch Window Up" = "Meta+K";
        "Window Close" = "Alt+F4";
        "Window Maximize" = "Meta+Up";
        "Window Minimize" = "Meta+Down";
        "Toggle Present Windows (All desktops)" = "Meta+Tab";
      };
    };

    # Custom hotkeys
    hotkeys.commands = {
      "launch-konsole" = {
        name = "Launch Konsole";
        key = "Meta+Return";
        command = "konsole";
      };
      "launch-browser" = {
        name = "Launch Firefox";
        key = "Meta+B";
        command = "firefox";
      };
      "launch-filemanager" = {
        name = "Launch Dolphin";
        key = "Meta+E";
        command = "dolphin";
      };
    };

    # KRunner configuration
    krunner = {
      historyBehavior = "enableAutoComplete";
    };

    # Desktop effects
    configFile = {
      # Disable Baloo file indexing to improve performance
      "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;

      # Window decoration settings
      "kwinrc"."org.kde.kdecoration2"."ButtonsOnLeft" = "XAI";
      "kwinrc"."org.kde.kdecoration2"."ButtonsOnRight" = "FSM";

      # Configure virtual desktops
      "kwinrc"."Desktops" = {
        "Name_1" = "Main";
        "Name_2" = "Web";
        "Name_3" = "Code";
        "Name_4" = "Media";
        "Number" = 4;
        "Rows" = 1;
      };

      # Disable wallet password prompt
      "kwalletrc"."Wallet"."Prompt on Open" = false;

      # Disable checksum verification to speed up startup
      "kded5rc"."Module-checksums"."Disabled" = true;

      # Improve Dolphin performance
      "dolphinrc"."General"."RememberOpenedTabs" = false;
    };

    # Configure spectacle screenshots
    spectacle = {
      shortcuts = {
        captureRectangularRegion = "Meta+Shift+3";
        captureActiveWindow = "Meta+Shift+4";
        captureCurrentMonitor = "Meta+Shift+5";
        captureEntireDesktop = "Meta+Shift+6";
      };
    };
  };
}
