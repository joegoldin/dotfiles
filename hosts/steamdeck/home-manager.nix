# hosts/steamdeck/home-manager.nix
# Lean home-manager for Steam Deck — cherry-picked modules, no dev tools
{
  username,
  homeDirectory,
  stateVersion,
  ...
}:
{
  imports = [
    ../common/home/fish
    ../common/home/git.nix
    ../common/home/gh.nix
    ../common/home/starship.nix
    ../common/home/gpg.nix
    ../common/home/bin
    ../common/home/plasma.nix
    ../common/home/default-apps.nix
    ../common/home/firefox
    ./packages.nix
  ];

  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";

  home = {
    inherit stateVersion username homeDirectory;
  };

  # Override 1Password SSH agent from plasma.nix — not used on Deck
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = { };
    extraConfig = "";
  };

  programs.plasma = {
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
                "applications:firefox.desktop"
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

    hotkeys.commands = {
      "launch-browser" = {
        name = "Launch Firefox";
        key = "Meta+B";
        command = "firefox";
      };
    };
  };
}
