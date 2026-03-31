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
  inherit (lib) attrValues makeSearchPathOutput mkForce;

  defaultSession = "plasma";

  switch-session = pkgs.writeShellApplication {
    name = "switch-session";
    text = ''
      mkdir -p /etc/sddm.conf.d
      cat <<EOF | tee /etc/sddm.conf.d/autologin.conf
      [Autologin]
      User=${username}
      Session=$1
      Relogin=true
      EOF
    '';
  };

  gaming-mode = pkgs.writeShellScriptBin "gaming-mode" ''
    sudo ${pkgs.systemd}/bin/systemctl start to-gaming-mode.service
  '';
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
    desktopSession = defaultSession;

    environment = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS =
        makeSearchPathOutput "steamcompattool" ""
          config.programs.steam.extraCompatPackages;
    };
  };

  # SDDM with auto-login and relogin for seamless session switching
  services.displayManager.sddm = {
    enable = true;
    autoLogin.relogin = true;
    wayland = {
      enable = true;
      compositorCommand = "kwin";
    };
    settings.General.InputMethod = "qtvirtualkeyboard";
  };

  # Set default session at boot
  systemd.services."set-session" = {
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    path = [ switch-session ];
    script = ''
      switch-session "${defaultSession}"
    '';
  };

  # Disable getty on tty1 for seamless session transitions
  systemd.services.display-manager.conflicts = [ "getty@tty1.service" ];

  # Switch to gaming mode service
  systemd.services."to-gaming-mode" = {
    wantedBy = mkForce [ ];
    path = [ switch-session ];
    script = ''
      switch-session "gamescope-wayland"
      systemctl restart display-manager
      sleep 10
      switch-session "${defaultSession}"
    '';
  };

  # Allow user to switch to gaming mode without password
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl start to-gaming-mode.service";
          options = [
            "SETENV"
            "NOPASSWD"
          ];
        }
      ];
    }
  ];

  # Gaming Mode desktop shortcut
  environment.systemPackages = with pkgs; [
    gaming-mode
    steam-rom-manager
    r2modman
  ];

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

  # Fonts
  fonts.packages =
    let
      customFonts = import ../common/system/fonts { inherit pkgs lib dotfiles-assets; };
    in
    [ customFonts.berkeley-mono-nerd-font ];
}
