# Desktop-specific Plasma config: activities, hotkeys, hand-picked
# kde settings, spectacle. Shared plasma config (plasmoids, ssh agent,
# workspace theme, run_all activation) lives in modules/home/plasma.nix;
# generated payloads sit in ./_plasma-panels.nix and ./_plasma-tiling.nix.
{ ... }:
{
  den.aspects.elphael.homeManager = {
    imports = [
      ./_plasma-panels.nix
      ./_plasma-tiling.nix
    ];

    programs.plasma = {
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
          name = "Launch Zen";
          key = "Meta+B";
          command = "zen";
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
        "plasmanotifyrc"."Applications/com.mitchellh.ghostty"."Seen" = true;
        "plasmanotifyrc"."Applications/discord"."Seen" = true;
        "plasmanotifyrc"."Applications/zen"."Seen" = true;
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
  };
}
