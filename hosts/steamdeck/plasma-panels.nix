# hosts/steamdeck/plasma-panels.nix
# Panel layout for Steam Deck desktop mode
_: {
  programs.plasma.panels = [
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
              "applications:zen.desktop"
              "applications:steam.desktop"
            ];
          };
        }
        "org.kde.plasma.marginsseparator"
        "org.kde.plasma.manageinputmethod"
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
}
