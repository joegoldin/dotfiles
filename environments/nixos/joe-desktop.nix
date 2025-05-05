# environments/nixos/joe-desktop.nix
# Specific configuration for joe-desktop tower machine
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable X11/Wayland and KDE Plasma 6 desktop environment
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    # Disable Plasma 5
    # desktopManager.plasma5.enable = true;
  };

  # Enable Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Enable XDG desktop portal for better application integration
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-kde];
  };

  # Enable sound with PipeWire (recommended for Plasma 6)
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  # Disable PulseAudio as it conflicts with PipeWire
  hardware.pulseaudio.enable = false;

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enable printing
  services.printing.enable = true;

  # Enable firmware updates
  services.fwupd.enable = true;

  # Additional system packages
  environment.systemPackages = with pkgs; [
    # System utils
    gparted
    htop
    glxinfo
    pciutils
    usbutils

    # Basic GUI apps
    firefox
    vlc

    # KDE specific packages for Plasma 6
    kdePackages.kate
    kdePackages.ark
    kdePackages.spectacle
    kdePackages.dolphin
    kdePackages.konsole
  ];

  # Enable flatpak
  services.flatpak.enable = true;
}
