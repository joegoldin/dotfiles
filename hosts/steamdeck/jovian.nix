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
  inherit (lib) attrValues makeSearchPathOutput;
in
{
  # Steam Deck hardware
  jovian.devices.steamdeck.enable = true;
  jovian.devices.steamdeck.enableVendorDrivers = true;
  jovian.hardware.has.amd.gpu = true;

  # Steam + gamescope session
  jovian.steam = {
    enable = true;
    user = username;
    desktopSession = "plasma";

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

  # Seed the SDDM autologin config that steamos-manager expects
  # steamos-manager checks for /etc/sddm.conf.d/steamos.conf to enable SessionManagement1
  environment.etc."sddm.conf.d/steamos.conf".text = ''
    [Autologin]
    User=${username}
    Session=gamescope-wayland
    Relogin=true
  '';

  # Default to gamescope on boot
  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };
  services.displayManager.defaultSession = "gamescope-wayland";

  # Disable getty on tty1 for seamless session transitions
  systemd.services.display-manager.conflicts = [ "getty@tty1.service" ];

  # Additional Steam config (merged with gaming.nix)
  programs.steam = {
    protontricks.enable = true;
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

  # Extra gaming packages
  environment.systemPackages = with pkgs; [
    steam-rom-manager
    r2modman
  ];

  # Fonts
  fonts.packages =
    let
      customFonts = import ../common/system/fonts { inherit pkgs lib dotfiles-assets; };
    in
    [ customFonts.berkeley-mono-nerd-font ];
}
