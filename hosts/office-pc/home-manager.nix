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
    ../common/home/packages/workstation.nix
    ../common/home/zen
    ../common/home/plasma.nix
    ../common/home/zed.nix
    ../common/home/ghostty.nix
    ../common/home/mouse-actions
    ./packages.nix
    ./python.nix
    ./plasma-panels.nix
  ];

  programs.plasma = {
    # office-pc specific hotkeys
    hotkeys.commands = {
      "launch-terminal" = {
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
