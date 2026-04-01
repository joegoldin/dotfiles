# hosts/steamdeck/jovian.nix
# Jovian NixOS: Steam Deck hardware, Game Mode, desktop switching, Decky Loader
{
  config,
  pkgs,
  lib,
  username,
  dotfiles-assets,
  ...
}:
let
  inherit (lib) attrValues makeSearchPathOutput getExe;

  restartNetwork = getExe (
    pkgs.writeShellApplication {
      name = "restart-network";
      runtimeInputs = with pkgs; [ systemd ];
      text = "systemctl restart NetworkManager";
    }
  );
in
{
  # Steam Deck hardware
  jovian.devices.steamdeck.enable = true;
  jovian.devices.steamdeck.enableVendorDrivers = true;
  jovian.hardware.has.amd.gpu = true;

  # Steam + gamescope session (SDDM handles session switching, not autoStart)
  jovian.steam = {
    enable = true;
    user = username;

    environment = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS =
        makeSearchPathOutput "steamcompattool" ""
          config.programs.steam.extraCompatPackages;
    };
  };

  # SDDM manages session switching (steamos-manager writes to /etc/sddm.conf.d/)
  services.displayManager.sddm = {
    enable = true;
    wayland = {
      enable = true;
      compositorCommand = "kwin";
    };
    autoLogin.relogin = true;
    settings.General.InputMethod = "qtvirtualkeyboard";
  };

  # Session switching: steamos-manager writes to /etc/sddm.conf.d/ at runtime.
  # We do NOT use services.displayManager.autoLogin or defaultSession because
  # they write Session= into the read-only /etc/sddm.conf which can't be overridden.
  # Instead, steamos.conf in the writable conf.d/ handles autologin + session selection.
  systemd.tmpfiles.rules = [
    "d /etc/sddm.conf.d 0755 root root -"
    "f /etc/sddm.conf.d/steamos.conf 0644 root root - [Autologin]\\nUser=${username}\\nSession=gamescope-wayland\\nRelogin=true"
  ];

  # Disable getty on tty1 for seamless session transitions
  systemd.services.display-manager.conflicts = [ "getty@tty1.service" ];

  # Allow passwordless network restart on session switch
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = restartNetwork;
          options = [
            "SETENV"
            "NOPASSWD"
          ];
        }
      ];
    }
  ];

  # Steam hardware udev rules
  hardware.steam-hardware.enable = true;

  # Additional Steam config (merged with gaming.nix)
  programs.steam = {
    protontricks.enable = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
    extraPackages = attrValues {
      inherit (pkgs) flatpak;
      inherit (pkgs.kdePackages) breeze;
    };
  };

  # Decky Loader
  jovian.decky-loader = {
    enable = true;
    user = username;
    stateDir = "/home/${username}/.local/share/decky";

    extraPackages = attrValues {
      inherit (pkgs)
        gawk
        curl
        unzip
        util-linux
        gnugrep
        readline
        procps
        pciutils
        flatpak
        libpulseaudio
        ;
    };

    extraPythonPackages = p: with p; [ click ];
  };

  # Extra gaming packages + virtual keyboard for SDDM
  environment.systemPackages = with pkgs; [
    steam-rom-manager
    r2modman
    kdePackages.qtvirtualkeyboard
  ];

  # Fonts
  fonts.packages =
    let
      customFonts = import ../common/system/fonts { inherit pkgs lib dotfiles-assets; };
    in
    [ customFonts.berkeley-mono-nerd-font ];
}
