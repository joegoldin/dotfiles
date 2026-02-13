# hosts/nixos/system/joe-desktop.nix
# Specific configuration for joe-desktop tower machine
{
  config,
  pkgs,
  lib,
  username,
  dotfiles-assets,
  ...
}: let
  fonts = import ../../common/system/fonts {inherit pkgs lib dotfiles-assets;};
in {
  # TODO: Add litra-autotoggle as a service to systemd

  # ssh with 1password
  environment.sessionVariables = {
    SSH_AUTH_SOCK = "/home/${username}/.1password/agent.sock";
  };

  # Enable X11/Wayland and KDE Plasma 6 desktop environment
  services.displayManager.sddm.enable = true;
  services.xserver = {
    enable = true;
    displayManager.sessionCommands = ''
      ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
    '';
    videoDrivers = ["amdgpu" "displaylink" "modesetting"];
  };

  systemd.services.dlm.wantedBy = ["multi-user.target"];

  # "Most software has the HIP libraries hard-coded. You can work around it on NixOS by using:"
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
  ];

  # Enable Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Enable XDG desktop portal for better application integration
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
  };

  # Enable sound with PipeWire (recommended for Plasma 6)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  # Disable PulseAudio as it conflicts with PipeWire
  services.pulseaudio.enable = false;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enable printing
  services.printing.enable = true;
  services.samba.enable = true;
  services.printing.drivers = with pkgs; [gutenprint hplip hplipWithPlugin];

  # Enable firmware updates
  services.fwupd.enable = true;

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
  fonts.packages = with pkgs; [
    fonts.berkeley-mono-nerd-font
  ];

  # Enable flatpak
  services.flatpak.enable = true;
}
