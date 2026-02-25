{ username, ... }:
{
  imports = [
    ../common/home
    ../common/home/firefox
    ./packages.nix
    ./ghostty.nix
    ../common/home/zed.nix
    ../common/home/default-apps.nix
    ./dolphin.nix
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

  # ssh with 1password
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        identityAgent = "\"/home/${username}/.1password/agent.sock\"";
      };
    };
    extraConfig = ''
      IdentityAgent "/home/${username}/.1password/agent.sock"
    '';
  };

  programs.plasma = {
    enable = true;

    # Workspace appearance
    workspace = {
      theme = "breeze-dark";
      # Managed by custom script via systemd timer
      # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/5120x2880.png";
      lookAndFeel = "org.kde.breezedark.desktop";
      clickItemTo = "select"; # Options are "select" or "open"
    };

    # Panel configuration
    panels = [
      # Main panel at the bottom
      {
        location = "bottom";
        floating = false;
        height = 38;
        widgets = [
          {
            kickoff = {
              popupHeight = 509;
              popupWidth = 647;
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
                "applications:us.zoom.Zoom.desktop"
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

    # Shortcuts
    shortcuts = {
      "ActivityManager"."switch-to-activity-8a44913d-258b-4faf-b84c-6815d74e5cf1" = [ ];
      "ActivityManager"."switch-to-activity-aa47102b-a33c-407f-8039-dbf5985eb3e6" = [ ];
      "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Alt+K";
      "kaccess"."Toggle Screen Reader On and Off" = "Meta+Alt+S";
      "kcm_touchpad"."Disable Touchpad" = "Touchpad Off";
      "kcm_touchpad"."Enable Touchpad" = "Touchpad On";
      "kcm_touchpad"."Toggle Touchpad" = [
        "Touchpad Toggle"
        "Meta+Ctrl+Zenkaku Hankaku,Touchpad Toggle"
        "Meta+Ctrl+Zenkaku Hankaku"
      ];
      "kmix"."decrease_microphone_volume" = "Microphone Volume Down";
      "kmix"."decrease_volume" = "Volume Down";
      "kmix"."decrease_volume_small" = "Shift+Volume Down";
      "kmix"."increase_microphone_volume" = "Microphone Volume Up";
      "kmix"."increase_volume" = "Volume Up";
      "kmix"."increase_volume_small" = "Shift+Volume Up";
      "kmix"."mic_mute" = [
        "Microphone Mute"
        "Meta+Volume Mute,Microphone Mute"
        "Meta+Volume Mute,Mute Microphone"
      ];
      "kmix"."mute" = "Volume Mute";
      "ksmserver"."Halt Without Confirmation" = "none,,Shut Down Without Confirmation";
      "ksmserver"."Lock Session" = [
        "Meta+L"
        "Screensaver,Lock Session"
      ];
      "ksmserver"."Log Out" = "Ctrl+Alt+Del";
      "ksmserver"."Log Out Without Confirmation" = "none,,Log Out Without Confirmation";
      "ksmserver"."LogOut" = "none,,Log Out";
      "ksmserver"."Reboot" = "none,,Reboot";
      "ksmserver"."Reboot Without Confirmation" = "none,,Reboot Without Confirmation";
      "ksmserver"."Shut Down" = "none,,Shut Down";
      "kwin"."Activate Window Demanding Attention" = "Meta+Ctrl+A";
      "kwin"."Cycle Overview" = [ ];
      "kwin"."Cycle Overview Opposite" = [ ];
      "kwin"."Decrease Opacity" = "none,,Decrease Opacity of Active Window by 5%";
      "kwin"."Edit Tiles" = "Meta+T";
      "kwin"."Expose" = "Ctrl+F9";
      "kwin"."ExposeAll" = [
        "Ctrl+F10"
        "Launch (C),Ctrl+F10"
        "Launch (C),Toggle Present Windows (All desktops)"
      ];
      "kwin"."ExposeClass" = "Ctrl+F7";
      "kwin"."ExposeClassCurrentDesktop" = [ ];
      "kwin"."Grid View" = "Meta+G";
      "kwin"."Increase Opacity" = "none,,Increase Opacity of Active Window by 5%";
      "kwin"."Kill Window" = "Meta+Ctrl+Esc";
      "kwin"."Move Tablet to Next Output" = [ ];
      "kwin"."MoveMouseToCenter" = "Meta+F6";
      "kwin"."MoveMouseToFocus" = "Meta+F5";
      "kwin"."MoveZoomDown" = [ ];
      "kwin"."MoveZoomLeft" = [ ];
      "kwin"."MoveZoomRight" = [ ];
      "kwin"."MoveZoomUp" = [ ];
      "kwin"."Overview" = "Meta+W";
      "kwin"."Setup Window Shortcut" = "none,,Setup Window Shortcut";
      "kwin"."Show Desktop" = "Meta+D";
      "kwin"."Switch One Desktop Down" = "Meta+Ctrl+Down";
      "kwin"."Switch One Desktop Up" = "Meta+Ctrl+Up";
      "kwin"."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
      "kwin"."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
      "kwin"."Switch Window Down" = "Meta+J,Meta+Alt+Down,Switch to Window Below";
      "kwin"."Switch Window Left" = "Meta+H,Meta+Alt+Left,Switch to Window to the Left";
      "kwin"."Switch Window Right" = "none,Meta+Alt+Right,Switch to Window to the Right";
      "kwin"."Switch Window Up" = "Meta+K,Meta+Alt+Up,Switch to Window Above";
      "kwin"."Switch to Desktop 1" = "Meta+1,Ctrl+F1,Switch to Desktop 1";
      "kwin"."Switch to Desktop 10" = "none,,Switch to Desktop 10";
      "kwin"."Switch to Desktop 11" = "none,,Switch to Desktop 11";
      "kwin"."Switch to Desktop 12" = "none,,Switch to Desktop 12";
      "kwin"."Switch to Desktop 13" = "none,,Switch to Desktop 13";
      "kwin"."Switch to Desktop 14" = "none,,Switch to Desktop 14";
      "kwin"."Switch to Desktop 15" = "none,,Switch to Desktop 15";
      "kwin"."Switch to Desktop 16" = "none,,Switch to Desktop 16";
      "kwin"."Switch to Desktop 17" = "none,,Switch to Desktop 17";
      "kwin"."Switch to Desktop 18" = "none,,Switch to Desktop 18";
      "kwin"."Switch to Desktop 19" = "none,,Switch to Desktop 19";
      "kwin"."Switch to Desktop 2" = "Meta+2";
      "kwin"."Switch to Desktop 20" = "none,,Switch to Desktop 20";
      "kwin"."Switch to Desktop 3" = "Meta+3";
      "kwin"."Switch to Desktop 4" = "Meta+4";
      "kwin"."Switch to Desktop 5" = "none,,Switch to Desktop 5";
      "kwin"."Switch to Desktop 6" = "none,,Switch to Desktop 6";
      "kwin"."Switch to Desktop 7" = "none,,Switch to Desktop 7";
      "kwin"."Switch to Desktop 8" = "none,,Switch to Desktop 8";
      "kwin"."Switch to Desktop 9" = "none,,Switch to Desktop 9";
      "kwin"."Switch to Next Desktop" = "none,,Switch to Next Desktop";
      "kwin"."Switch to Next Screen" = "none,,Switch to Next Screen";
      "kwin"."Switch to Previous Desktop" = "none,,Switch to Previous Desktop";
      "kwin"."Switch to Previous Screen" = "none,,Switch to Previous Screen";
      "kwin"."Switch to Screen 0" = "none,,Switch to Screen 0";
      "kwin"."Switch to Screen 1" = "none,,Switch to Screen 1";
      "kwin"."Switch to Screen 2" = "none,,Switch to Screen 2";
      "kwin"."Switch to Screen 3" = "none,,Switch to Screen 3";
      "kwin"."Switch to Screen 4" = "none,,Switch to Screen 4";
      "kwin"."Switch to Screen 5" = "none,,Switch to Screen 5";
      "kwin"."Switch to Screen 6" = "none,,Switch to Screen 6";
      "kwin"."Switch to Screen 7" = "none,,Switch to Screen 7";
      "kwin"."Switch to Screen Above" = "none,,Switch to Screen Above";
      "kwin"."Switch to Screen Below" = "none,,Switch to Screen Below";
      "kwin"."Switch to Screen to the Left" = "none,,Switch to Screen to the Left";
      "kwin"."Switch to Screen to the Right" = "none,,Switch to Screen to the Right";
      "kwin"."Toggle Night Color" = [ ];
      "kwin"."Toggle Present Windows (All desktops)" = "Meta+Tab";
      "kwin"."Toggle Window Raise/Lower" = "none,,Toggle Window Raise/Lower";
      "kwin"."Walk Through Windows" = "Alt+Tab";
      "kwin"."Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
      "kwin"."Walk Through Windows Alternative" = "none,,Walk Through Windows Alternative";
      "kwin"."Walk Through Windows Alternative (Reverse)" =
        "none,,Walk Through Windows Alternative (Reverse)";
      "kwin"."Walk Through Windows of Current Application" = "Alt+`";
      "kwin"."Walk Through Windows of Current Application (Reverse)" = "Alt+~";
      "kwin"."Walk Through Windows of Current Application Alternative" =
        "none,,Walk Through Windows of Current Application Alternative";
      "kwin"."Walk Through Windows of Current Application Alternative (Reverse)" =
        "none,,Walk Through Windows of Current Application Alternative (Reverse)";
      "kwin"."Window Above Other Windows" = "none,,Keep Window Above Others";
      "kwin"."Window Below Other Windows" = "none,,Keep Window Below Others";
      "kwin"."Window Close" = "Alt+F4";
      "kwin"."Window Fullscreen" = "none,,Make Window Fullscreen";
      "kwin"."Window Grow Horizontal" = "none,,Expand Window Horizontally";
      "kwin"."Window Grow Vertical" = "none,,Expand Window Vertically";
      "kwin"."Window Lower" = "none,,Lower Window";
      "kwin"."Window Maximize" = "Meta+Up,Meta+PgUp,Maximize Window";
      "kwin"."Window Maximize Horizontal" = "none,,Maximize Window Horizontally";
      "kwin"."Window Maximize Vertical" = "none,,Maximize Window Vertically";
      "kwin"."Window Minimize" = "Meta+Down,Meta+PgDown,Minimize Window";
      "kwin"."Window Move" = "none,,Move Window";
      "kwin"."Window Move Center" = "none,,Move Window to the Center";
      "kwin"."Window No Border" = "none,,Toggle Window Titlebar and Frame";
      "kwin"."Window On All Desktops" = "none,,Keep Window on All Desktops";
      "kwin"."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
      "kwin"."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
      "kwin"."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
      "kwin"."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
      "kwin"."Window One Screen Down" = "none,,Move Window One Screen Down";
      "kwin"."Window One Screen Up" = "none,,Move Window One Screen Up";
      "kwin"."Window One Screen to the Left" = "none,,Move Window One Screen to the Left";
      "kwin"."Window One Screen to the Right" = "none,,Move Window One Screen to the Right";
      "kwin"."Window Operations Menu" = "Alt+F3";
      "kwin"."Window Pack Down" = "none,,Move Window Down";
      "kwin"."Window Pack Left" = "none,,Move Window Left";
      "kwin"."Window Pack Right" = "none,,Move Window Right";
      "kwin"."Window Pack Up" = "none,,Move Window Up";
      "kwin"."Window Quick Tile Bottom" = "none,Meta+Down,Quick Tile Window to the Bottom";
      "kwin"."Window Quick Tile Bottom Left" = "none,,Quick Tile Window to the Bottom Left";
      "kwin"."Window Quick Tile Bottom Right" = "none,,Quick Tile Window to the Bottom Right";
      "kwin"."Window Quick Tile Left" = "Meta+Left";
      "kwin"."Window Quick Tile Right" = "Meta+Right";
      "kwin"."Window Quick Tile Top" = "none,Meta+Up,Quick Tile Window to the Top";
      "kwin"."Window Quick Tile Top Left" = "none,,Quick Tile Window to the Top Left";
      "kwin"."Window Quick Tile Top Right" = "none,,Quick Tile Window to the Top Right";
      "kwin"."Window Raise" = "none,,Raise Window";
      "kwin"."Window Resize" = "none,,Resize Window";
      "kwin"."Window Shade" = "none,,Shade Window";
      "kwin"."Window Shrink Horizontal" = "none,,Shrink Window Horizontally";
      "kwin"."Window Shrink Vertical" = "none,,Shrink Window Vertically";
      "kwin"."Window to Desktop 1" = "none,,Window to Desktop 1";
      "kwin"."Window to Desktop 10" = "none,,Window to Desktop 10";
      "kwin"."Window to Desktop 11" = "none,,Window to Desktop 11";
      "kwin"."Window to Desktop 12" = "none,,Window to Desktop 12";
      "kwin"."Window to Desktop 13" = "none,,Window to Desktop 13";
      "kwin"."Window to Desktop 14" = "none,,Window to Desktop 14";
      "kwin"."Window to Desktop 15" = "none,,Window to Desktop 15";
      "kwin"."Window to Desktop 16" = "none,,Window to Desktop 16";
      "kwin"."Window to Desktop 17" = "none,,Window to Desktop 17";
      "kwin"."Window to Desktop 18" = "none,,Window to Desktop 18";
      "kwin"."Window to Desktop 19" = "none,,Window to Desktop 19";
      "kwin"."Window to Desktop 2" = "none,,Window to Desktop 2";
      "kwin"."Window to Desktop 20" = "none,,Window to Desktop 20";
      "kwin"."Window to Desktop 3" = "none,,Window to Desktop 3";
      "kwin"."Window to Desktop 4" = "none,,Window to Desktop 4";
      "kwin"."Window to Desktop 5" = "none,,Window to Desktop 5";
      "kwin"."Window to Desktop 6" = "none,,Window to Desktop 6";
      "kwin"."Window to Desktop 7" = "none,,Window to Desktop 7";
      "kwin"."Window to Desktop 8" = "none,,Window to Desktop 8";
      "kwin"."Window to Desktop 9" = "none,,Window to Desktop 9";
      "kwin"."Window to Next Desktop" = "none,,Window to Next Desktop";
      "kwin"."Window to Next Screen" = "Meta+Shift+Right";
      "kwin"."Window to Previous Desktop" = "none,,Window to Previous Desktop";
      "kwin"."Window to Previous Screen" = "Meta+Shift+Left";
      "kwin"."Window to Screen 0" = "none,,Move Window to Screen 0";
      "kwin"."Window to Screen 1" = "none,,Move Window to Screen 1";
      "kwin"."Window to Screen 2" = "none,,Move Window to Screen 2";
      "kwin"."Window to Screen 3" = "none,,Move Window to Screen 3";
      "kwin"."Window to Screen 4" = "none,,Move Window to Screen 4";
      "kwin"."Window to Screen 5" = "none,,Move Window to Screen 5";
      "kwin"."Window to Screen 6" = "none,,Move Window to Screen 6";
      "kwin"."Window to Screen 7" = "none,,Move Window to Screen 7";
      "kwin"."view_actual_size" = "Meta+0";
      "kwin"."view_zoom_in" = [
        "Meta++"
        "Meta+=,Meta++"
        "Meta+=,Zoom In"
      ];
      "kwin"."view_zoom_out" = "Meta+-";
      "mediacontrol"."mediavolumedown" = "none,,Media volume down";
      "mediacontrol"."mediavolumeup" = "none,,Media volume up";
      "mediacontrol"."nextmedia" = "Media Next";
      "mediacontrol"."pausemedia" = "Media Pause";
      "mediacontrol"."playmedia" = "none,,Play media playback";
      "mediacontrol"."playpausemedia" = "Media Play";
      "mediacontrol"."previousmedia" = "Media Previous";
      "mediacontrol"."stopmedia" = "Media Stop";
      "org_kde_powerdevil"."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
      "org_kde_powerdevil"."Decrease Screen Brightness" = "Monitor Brightness Down";
      "org_kde_powerdevil"."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
      "org_kde_powerdevil"."Hibernate" = "Hibernate";
      "org_kde_powerdevil"."Increase Keyboard Brightness" = "Keyboard Brightness Up";
      "org_kde_powerdevil"."Increase Screen Brightness" = "Monitor Brightness Up";
      "org_kde_powerdevil"."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
      "org_kde_powerdevil"."PowerDown" = "Power Down";
      "org_kde_powerdevil"."PowerOff" = "Power Off";
      "org_kde_powerdevil"."Sleep" = "Sleep";
      "org_kde_powerdevil"."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
      "org_kde_powerdevil"."Turn Off Screen" = [ ];
      "org_kde_powerdevil"."powerProfile" = [
        "Battery"
        "Meta+B,Battery"
        "Meta+B,Switch Power Profile"
      ];
      "plasmashell"."activate application launcher" = [
        "Meta"
        "Alt+F1,Meta"
        "Alt+F1,Activate Application Launcher"
      ];
      "plasmashell"."activate task manager entry 1" = "none,Meta+1,Activate Task Manager Entry 1";
      "plasmashell"."activate task manager entry 10" = "none,Meta+0,Activate Task Manager Entry 10";
      "plasmashell"."activate task manager entry 2" = "none,Meta+2,Activate Task Manager Entry 2";
      "plasmashell"."activate task manager entry 3" = "none,Meta+3,Activate Task Manager Entry 3";
      "plasmashell"."activate task manager entry 4" = "none,Meta+4,Activate Task Manager Entry 4";
      "plasmashell"."activate task manager entry 5" = "Meta+5";
      "plasmashell"."activate task manager entry 6" = "Meta+6";
      "plasmashell"."activate task manager entry 7" = "Meta+7";
      "plasmashell"."activate task manager entry 8" = "Meta+8";
      "plasmashell"."activate task manager entry 9" = "Meta+9";
      "plasmashell"."clear-history" = "none,,Clear Clipboard History";
      "plasmashell"."clipboard_action" = "Meta+Ctrl+X";
      "plasmashell"."cycle-panels" = "Meta+Alt+P";
      "plasmashell"."cycleNextAction" = "none,,Next History Item";
      "plasmashell"."cyclePrevAction" = "none,,Previous History Item";
      "plasmashell"."manage activities" = "Meta+Q";
      "plasmashell"."next activity" = "Meta+A,none,Walk through activities";
      "plasmashell"."previous activity" = "Meta+Shift+A,none,Walk through activities (Reverse)";
      "plasmashell"."repeat_action" = "none,Meta+Ctrl+R,Manually Invoke Action on Current Clipboard";
      "plasmashell"."show dashboard" = "Ctrl+F12";
      "plasmashell"."show-barcode" = "none,,Show Barcode…";
      "plasmashell"."show-on-mouse-pos" = "Meta+V";
      "plasmashell"."stop current activity" = "Meta+S";
      "plasmashell"."switch to next activity" = "none,,Switch to Next Activity";
      "plasmashell"."switch to previous activity" = "none,,Switch to Previous Activity";
      "plasmashell"."toggle do not disturb" = "none,,Toggle do not disturb";
      "services/org.kde.dolphin.desktop"."_launch" = [ ];
      "services/com.mitchellh.ghostty.desktop"."_launch" = [ ];
      "kwin"."Window Custom Quick Tile Bottom" = [ ];
      "kwin"."Window Custom Quick Tile Left" = [ ];
      "kwin"."Window Custom Quick Tile Right" = [ ];
      "kwin"."Window Custom Quick Tile Top" = [ ];
      "kwin"."disableInputCapture" = "Meta+Shift+Esc";
      "plasmashell"."Slideshow Wallpaper Next Image" = [ ];
      "plasmashell"."edit_clipboard" = [ ];
    };

    # Custom hotkeys
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
      # Power management: no auto-suspend, power button sleeps, screen off after 15min
      "powerdevilrc"."AC/Display"."TurnOffDisplayIdleTimeoutSec" = 900;
      "powerdevilrc"."AC/Display"."TurnOffDisplayIdleTimeoutWhenLockedSec" = 20;
      "powerdevilrc"."AC/SuspendAndShutdown"."AutoSuspendAction" = 0;
      "powerdevilrc"."AC/SuspendAndShutdown"."PowerButtonAction" = 1;
      "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
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

      "kcminputrc"."Keyboard"."NumLock" = 0; # 0 = on, 1 = off, 2 = unchanged
      "kcminputrc"."Libinput/4815/3077/Mad Catz Global MADCATZ R.A.T. 8+ gaming mouse"."PointerAccelerationProfile" =
        1;
      "kcminputrc"."Libinput/4815/3077/Mad Catz Global MADCATZ R.A.T. 8+ gaming mouse"."ScrollMethod" = 0;
      "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
      "kded5rc"."Module-checksums"."Disabled" = true;
      "kded5rc"."Module-device_automounter"."autoload" = false;
      "kdeglobals"."DirSelect Dialog"."DirSelectDialog Size" = "980,600";
      "kdeglobals"."General"."XftHintStyle" = "hintslight";
      "kdeglobals"."General"."XftSubPixel" = "none";
      "kdeglobals"."General"."fixed" = "TX02 Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      "kdeglobals"."KDE"."DndBehavior" = "MoveIfSameDevice"; # drag files = move if same device
      "kdeglobals"."KDE"."SingleClick" = false;
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
      "krunnerrc"."General"."historyBehavior" = "ImmediateCompletion";
      "kscreenlockerrc"."Daemon"."Timeout" = 10;
      "kwalletrc"."Wallet"."First Use" = false;
      "kwalletrc"."Wallet"."Prompt on Open" = false;
      "kwinrc"."Desktops"."Id_1" = "003e92e5-0a93-4e80-9e46-abcefff2f6ed";
      "kwinrc"."Desktops"."Name_1" = "Main";
      "kwinrc"."Desktops"."Number" = 1;
      "kwinrc"."Desktops"."Rows" = 1;
      "kwinrc"."Plugins"."kzonesEnabled" = false;
      "kwinrc"."Plugins"."synchronizeskipswitcherEnabled" = true;
      "kwinrc"."Script-kzones"."trackLayoutPerScreen" = true;
      "kwinrc"."Tiling"."padding" = 4;
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
      "kwinrc"."Wayland"."EnablePrimarySelection" = false; # disable middle-click paste
      "kwinrc"."Xwayland"."Scale" = 1;
      "kwinrc"."org.kde.kdecoration2"."ButtonsOnLeft" = "XAI";
      "kwinrc"."org.kde.kdecoration2"."ButtonsOnRight" = "FSM";
      "kxkbrc"."Layout"."Options" = "caps:ctrl_modifier";
      "kxkbrc"."Layout"."ResetOldOptions" = true;
      "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
      "plasmanotifyrc"."Applications/com.mitchellh.ghostty"."Seen" = true;
      "plasmanotifyrc"."Applications/discord"."Seen" = true;
      "plasmanotifyrc"."Applications/firefox"."Seen" = true;
      "plasmanotifyrc"."Applications/slack"."Seen" = true;
      "plasmaparc"."General"."RaiseMaximumVolume" = true;
      "plasmarc"."Theme"."name" = "breeze-dark";
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
