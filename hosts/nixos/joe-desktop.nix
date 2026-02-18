# hosts/nixos/system/joe-desktop.nix
# Specific configuration for joe-desktop tower machine
{
  pkgs,
  lib,
  username,
  dotfiles-assets,
  ...
}: let
  fonts = import ../common/system/fonts {inherit pkgs lib dotfiles-assets;};
in {
  # TODO: Add litra-autotoggle as a service to systemd

  # ssh with 1password
  environment.sessionVariables = {
    SSH_AUTH_SOCK = "/home/${username}/.1password/agent.sock";
  };

  systemd = {
    services.dlm.wantedBy = ["multi-user.target"];

    # "Most software has the HIP libraries hard-coded. You can work around it on NixOS by using:"
    tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };
    bluetooth.enable = true;
  };

  services = {
    # Enable X11/Wayland and KDE Plasma 6 desktop environment
    displayManager.sddm.enable = true;
    xserver = {
      enable = true;
      displayManager.sessionCommands = ''
        ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
      '';
      videoDrivers = [
        "amdgpu"
        "displaylink"
        "modesetting"
      ];
    };
    desktopManager.plasma6.enable = true;

    # Enable sound with PipeWire (recommended for Plasma 6)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire."99-pulsemeeter" = {
        "context.properties" = {
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 512;
          "default.clock.max-quantum" = 2048;
        };
      };
    };
    # Disable PulseAudio as it conflicts with PipeWire
    pulseaudio.enable = false;

    blueman.enable = true;

    # Enable printing
    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        hplip
        hplipWithPlugin
      ];
    };
    samba.enable = true;

    # Enable firmware updates
    fwupd.enable = true;

    # Enable flatpak
    flatpak.enable = true;
  };

  # Rootless Docker
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Enable XDG desktop portal for better application integration
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
  };

  security.rtkit.enable = true;

  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Drivers
    unstable.displaylink

    # System utils
    clinfo
    mesa-demos # replaces glxinfo
    gparted
    htop
    ntfs3g
    pciutils
    usbutils

    # KDE specific packages for Plasma 6
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.konsole
    kdePackages.spectacle
    kdotool
  ];

  # Fonts
  fonts.packages = [
    fonts.berkeley-mono-nerd-font
  ];
}
