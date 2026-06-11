# hosts/office-pc/home-manager.nix
{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../home/_hm
    ../../home/_hm/default-apps.nix
    ../../home/_hm/packages/workstation.nix
    ../../home/_hm/packages/linux-workstation.nix
    ../../home/_hm/zen
    ../../home/_hm/plasma.nix
    ../../home/_hm/zed.nix
    ../../home/_hm/ghostty.nix
    ../../home/_hm/mouse-actions
    ./_python.nix
    ./_plasma-panels.nix
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
