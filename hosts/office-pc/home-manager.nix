# hosts/office-pc/home-manager.nix
{ ... }:
{
  imports = [
    ../common/home
    ../common/home/plasma.nix
    ./packages.nix
    ./python.nix
  ];

  programs.plasma = {
    # Minimal panel for compute box
    panels = [
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
                "applications:org.kde.konsole.desktop"
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

    # office-pc specific hotkeys
    hotkeys.commands = {
      "launch-terminal" = {
        name = "Launch Konsole";
        key = "Meta+Return";
        command = "konsole";
      };
    };
  };
}
