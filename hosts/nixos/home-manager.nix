{ username, ... }:
{
  imports = [
    ../common/home
    ../common/home/plasma.nix
    ../common/home/firefox
    ./android.nix
    ./packages.nix
    ./python.nix
    ../common/home/ghostty.nix
    ../common/home/zed.nix
    ../common/home/default-apps.nix
    ./dolphin.nix
    ./easyeffects.nix
  ];

  # TODO: git signing with 1password
  # programs.git = {
  #   enable = true;
  #   extraConfig = {
  #     gpg = {
  #       format = "ssh";
  #     };
  #     gpg."ssh" = {
  #       program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
  #     };
  #     commit = {
  #       gpgsign = true;
  #     };

  #     # user = {
  #     #   signingKey = "...";
  #     # };
  #   };
  # };

  programs.plasma = {
    # Panel configuration (desktop-specific launchers)
    panels = [
      # Main panel at the bottom
      {
        location = "bottom";
        floating = false;
        height = 38;
        widgets = [
          {
            kicker = {
              icon = "start-here-kde-symbolic";
            };
          }
          {
            iconTasks = {
              behavior.grouping.method = "byProgramName";
              behavior.grouping.clickAction = "showTooltips";
              launchers = [
                "preferred://filemanager"
                "applications:firefox.desktop"
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
          "org.kde.plasma.systemtray"
          {
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
          }
        ];
      }
    ];

    # Desktop-specific shortcuts (activity UUIDs)
    shortcuts = {
      "ActivityManager"."switch-to-activity-8a44913d-258b-4faf-b84c-6815d74e5cf1" = [ ];
      "ActivityManager"."switch-to-activity-aa47102b-a33c-407f-8039-dbf5985eb3e6" = [ ];
    };

    # Desktop-specific hotkeys
    hotkeys.commands = {
      "launch-konsole" = {
        name = "Launch Ghostty";
        key = "Meta+Return";
        command = "ghostty";
      };
      "launch-browser" = {
        name = "Launch Firefox";
        key = "Meta+B";
        command = "firefox";
      };
    };

    # Desktop-specific config
    configFile = {
      "baloofilerc"."General"."dbVersion" = 2;
      "baloofilerc"."General"."exclude filters" =
        "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
      "baloofilerc"."General"."exclude filters version" = 9;
      "kactivitymanagerdrc"."activities"."8a44913d-258b-4faf-b84c-6815d74e5cf1" = "Default";
      "kactivitymanagerdrc"."main"."currentActivity" = "8a44913d-258b-4faf-b84c-6815d74e5cf1";
      "dolphinrc"."DetailsMode"."PreviewSize" = 16;
      "dolphinrc"."General"."RememberOpenedTabs" = false;
      "dolphinrc"."IconsMode"."PreviewSize" = 48;
      "dolphinrc"."KFileDialog Settings"."Places Icons Auto-resize" = false;
      "dolphinrc"."KFileDialog Settings"."Places Icons Static Size" = 22;

      "kcminputrc"."Libinput/4815/3077/Mad Catz Global MADCATZ R.A.T. 8+ gaming mouse"."PointerAccelerationProfile" =
        1;
      "kcminputrc"."Libinput/4815/3077/Mad Catz Global MADCATZ R.A.T. 8+ gaming mouse"."ScrollMethod" = 2;
      "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
      "kded5rc"."Module-checksums"."Disabled" = true;
      "kded5rc"."Module-device_automounter"."autoload" = false;
      "kdeglobals"."DirSelect Dialog"."DirSelectDialog Size" = "980,600";
      "kdeglobals"."KDE"."DndBehavior" = "MoveIfSameDevice"; # drag files = move if same device
      "kdeglobals"."KFileDialog Settings"."Allow Expansion" = false;
      "kdeglobals"."KFileDialog Settings"."Automatically select filename extension" = true;
      "kdeglobals"."KFileDialog Settings"."Breadcrumb Navigation" = true;
      "kdeglobals"."KFileDialog Settings"."Decoration position" = 2;
      "kdeglobals"."KFileDialog Settings"."LocationCombo Completionmode" = 5;
      "kdeglobals"."KFileDialog Settings"."PathCombo Completionmode" = 5;
      "kdeglobals"."KFileDialog Settings"."Show Bookmarks" = false;
      "kdeglobals"."KFileDialog Settings"."Show Full Path" = false;
      "kdeglobals"."KFileDialog Settings"."Show Inline Previews" = true;
      "kdeglobals"."KFileDialog Settings"."Show Preview" = false;
      "kdeglobals"."KFileDialog Settings"."Show Speedbar" = true;
      "kdeglobals"."KFileDialog Settings"."Show hidden files" = false;
      "kdeglobals"."KFileDialog Settings"."Sort by" = "Date";
      "kdeglobals"."KFileDialog Settings"."Sort directories first" = true;
      "kdeglobals"."KFileDialog Settings"."Sort hidden files last" = false;
      "kdeglobals"."KFileDialog Settings"."Sort reversed" = true;
      "kdeglobals"."KFileDialog Settings"."Speedbar Width" = 138;
      "kdeglobals"."KFileDialog Settings"."View Style" = "DetailTree";
      "kdeglobals"."WM"."activeBackground" = "49,54,59";
      "kdeglobals"."WM"."activeBlend" = "252,252,252";
      "kdeglobals"."WM"."activeForeground" = "252,252,252";
      "kdeglobals"."WM"."inactiveBackground" = "42,46,50";
      "kdeglobals"."WM"."inactiveBlend" = "161,169,177";
      "kdeglobals"."WM"."inactiveForeground" = "161,169,177";
      "kwinrc"."Desktops"."Id_1" = "003e92e5-0a93-4e80-9e46-abcefff2f6ed";
      "kwinrc"."Desktops"."Name_1" = "Main";
      "kwinrc"."Plugins"."kzonesEnabled" = false;
      "kwinrc"."Plugins"."synchronizeskipswitcherEnabled" = true;
      "kwinrc"."Script-kzones"."trackLayoutPerScreen" = true;
      # Per-virtual-desktop, per-monitor tiling layouts
      "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/1f2c90e2-3a8a-4a2e-831e-02e10fc958cd"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":[{"width":1}]}'';
      "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/2fd71289-0069-4dd8-b8d9-85a14c65cd2e"."tiles" =
        ''{"layoutDirection":"floating","tiles":[{"height":0.959259259259256,"width":0.8739583333333356,"x":0.03437500000000005,"y":0.012037037037036995},{"height":0.9888888888888838,"width":0.44427083333334144,"x":0.0005208333333335274,"y":0.004629629629629532},{"height":0.9879629629629589,"width":0.4630208333333371,"x":0.4567708333333289,"y":0.005555555555555555}]}'';
      "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/3f40670c-5b6f-4904-835d-62d17f2324f5"."tiles" =
        ''{"layoutDirection":"floating","tiles":[{"height":0.9990740740740734,"width":0.49479166666666985,"x":0,"y":0},{"height":0.991666666666667,"width":0.9380208333333211,"x":0.030208333333335988,"y":0},{"height":0.9999999999999997,"width":0.49895833333333195,"x":0.5010416666666622,"y":2.94469310047063e-16}]}'';
      "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/71cde4f2-86c2-44dc-9896-c4c025c5c5fb"."tiles" =
        ''{"layoutDirection":"floating","tiles":[{"height":0.9048611111111109,"width":0.9281249999999986,"x":0.04296875,"y":0.026388888888888882},{"height":0.7909722222222203,"width":0.3812499999999967,"x":0.0191406249999989,"y":0.05972222222222237},{"height":0.9118055555555532,"width":0.394140624999995,"x":0.597656250000001,"y":0.04791666666666706}]}'';
      "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/bd507e42-a7b4-4a0e-8871-ee8e19d10874"."tiles" =
        ''{"layoutDirection":"floating","tiles":[{"height":0.49322916666666655,"width":0.979629629629628,"x":0.011111111111110945,"y":0.010416666666666692},{"height":0.47447916666666745,"width":0.9703703703703689,"x":0.012962962962962671,"y":0.5156249999999998}]}'';
      "kwinrc"."Tiling/0bde4fed-54b1-5a65-a80d-e15f3cbd3f51"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":x5b{"width":0.25},{"width":0.5},{"width":0.25}x5d}'';
      "kwinrc"."Tiling/0d989076-4679-486f-b77a-d70ddebcf0b8/2fd71289-0069-4dd8-b8d9-85a14c65cd2e"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling/0d989076-4679-486f-b77a-d70ddebcf0b8/71cde4f2-86c2-44dc-9896-c4c025c5c5fb"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling/0d989076-4679-486f-b77a-d70ddebcf0b8/bd507e42-a7b4-4a0e-8871-ee8e19d10874"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling/3dfcd882-3b53-5dad-9264-f6f30f55e708"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":x5b{"width":0.25},{"width":0.5},{"width":0.25}x5d}'';
      "kwinrc"."Tiling/5914c4f2-13ba-5ca4-8d56-407f168ebfef"."tiles" =
        ''{"layoutDirection":"floating","tiles":x5b{"height":0.8583333333333333,"width":0.9494791666666667,"x":0.0171875,"y":0.0462962962962963}x5d}'';
      "kwinrc"."Tiling/5dfbdf8b-b6bc-57d9-8bf5-c73b48822a98"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":x5b{"width":0.25},{"width":0.5},{"width":0.25}x5d}'';
      "kwinrc"."Tiling/87014f83-7840-573e-aa8c-2c4c0ff954c2"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":x5b{"width":0.25},{"width":0.5},{"width":0.25}x5d}'';
      "kwinrc"."Tiling/9d26031a-0f2f-4fdf-9d21-14462065db3a/1f2c90e2-3a8a-4a2e-831e-02e10fc958cd"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling/9d26031a-0f2f-4fdf-9d21-14462065db3a/2fd71289-0069-4dd8-b8d9-85a14c65cd2e"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling/9d26031a-0f2f-4fdf-9d21-14462065db3a/3f40670c-5b6f-4904-835d-62d17f2324f5"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling/9d26031a-0f2f-4fdf-9d21-14462065db3a/71cde4f2-86c2-44dc-9896-c4c025c5c5fb"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling/9d26031a-0f2f-4fdf-9d21-14462065db3a/bd507e42-a7b4-4a0e-8871-ee8e19d10874"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
      "kwinrc"."Tiling/af452a7d-ff5a-5a61-a7d1-8663a64cd1ec"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":x5bx5d}'';
      "kwinrc"."Tiling/bfbeccc8-9101-5191-a12c-1c8669f3c4eb"."tiles" =
        ''{"layoutDirection":"floating","tiles":x5b{"height":0.4526041666666645,"width":0.9611111111111077,"x":0.01759259259259259,"y":0.5104166666666689},{"height":0.46979166666667393,"width":0.9666666666666612,"x":0.016666666666666597,"y":0.02395833333333642}x5d}'';
      "kwinrc"."Tiling/ce0b05ff-c107-52c0-97a5-422e8c49aef6"."tiles" =
        ''{"layoutDirection":"floating","tiles":x5b{"height":0.8892361111111093,"width":0.8942382812499999,"x":0.05,"y":0.05}x5d}'';
      "kwinrc"."Tiling/d371bb4f-2002-53ff-9df3-273219688491"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":x5b{"width":0.25},{"width":0.5},{"width":0.25}x5d}'';
      "kwinrc"."Tiling/e151800d-6cc9-5fed-9b34-1cad9484bacb"."tiles" =
        ''{"layoutDirection":"floating","tiles":x5b{"height":0.949999999999999,"width":0.9479166666666676,"x":0.025520833333333333,"y":0.0027777777777777775}x5d}'';
      "kwinrc"."Tiling/e6150747-0dca-5305-bd64-e7673cc0d170"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":x5b{"width":0.25},{"width":0.5},{"width":0.25}x5d}'';
      "kwinrc"."Tiling/f19ba19e-2ce1-5e23-ae4e-569a8e48ee92"."tiles" =
        ''{"layoutDirection":"horizontal","tiles":x5b{"layoutDirection":"floating","tiles":x5b{"height":0.8965277777777776,"width":0.7894531249999752,"x":0.07148437499999993,"y":0.050000000000000155},{"height":0.7597222222222202,"width":0.36015624999999607,"x":0.6312500000000021,"y":0.029861111111111085},{"height":0.8805555555555554,"width":0.45234375000000104,"x":0.016406250000003054,"y":0.020833333333333603}x5d,"width":0.9999999999999984}x5d}'';
      "plasmanotifyrc"."Applications/com.mitchellh.ghostty"."Seen" = true;
      "plasmanotifyrc"."Applications/discord"."Seen" = true;
      "plasmanotifyrc"."Applications/firefox"."Seen" = true;
      "plasmanotifyrc"."Applications/slack"."Seen" = true;
      "plasmaparc"."General"."RaiseMaximumVolume" = true;
      "spectaclerc"."ImageSave"."translatedScreenshotsFolder" = "Screenshots";
      "spectaclerc"."VideoSave"."translatedScreencastsFolder" = "Screencasts";
    };

    dataFile = {
      "dolphin/view_properties/global/.directory"."Dolphin"."SortOrder" = 1;
      "dolphin/view_properties/global/.directory"."Dolphin"."SortRole" = "modificationtime";
      "dolphin/view_properties/global/.directory"."Dolphin"."ViewMode" = 1;
    };

    # Configure spectacle screenshots
    spectacle = {
      shortcuts = {
        captureRectangularRegion = "Control+#";
        captureActiveWindow = "Control+$";
        captureCurrentMonitor = "Control+%";
        captureEntireDesktop = "Control+^";
      };
    };
  };
}
