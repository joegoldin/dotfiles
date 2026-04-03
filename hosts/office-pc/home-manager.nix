# hosts/office-pc/home-manager.nix
{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../common/home
    ../common/home/default-apps.nix
    ../common/home/firefox
    ../common/home/plasma.nix
    ../common/home/zed.nix
    ../common/home/ghostty.nix
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
                "applications:com.mitchellh.ghostty.desktop"
                "applications:firefox.desktop"
                "applications:discord.desktop"
                "applications:steam.desktop"
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

    # krdp server config
    configFile."krdpserverrc"."General" = {
      Certificate = "/home/${username}/.local/share/krdpserver/krdp.crt";
      CertificateKey = "/home/${username}/.local/share/krdpserver/krdp.key";
      SystemUserEnabled = false;
    };
  };

  # Autostart krdp server with the Plasma session
  systemd.user.services."krdp-server" = {
    Unit = {
      Description = "KDE RDP Server";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.krdp}/bin/krdp-server";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
