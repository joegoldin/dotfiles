# hosts/office-pc/office-pc.nix
# Specific configuration for office-pc compute machine
{
  pkgs,
  lib,
  username,
  dotfiles-assets,
  ...
}:
let
  fonts = import ../common/system/fonts { inherit pkgs lib dotfiles-assets; };
in
{
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    discover
    elisa
    kate
  ];

  environment.sessionVariables = {
    SSH_AUTH_SOCK = "/home/${username}/.1password/agent.sock";
  };

  systemd = {
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
  };

  services = {
    displayManager.sddm.enable = true;
    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
    };
    desktopManager.plasma6.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    pulseaudio.enable = false;
  };

  # Rootless Docker
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  users.extraGroups.docker.members = [ "${username}" ];
  users.extraGroups.kvm.members = [ "${username}" ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    clinfo
    mesa-demos
    btop-rocm
    pciutils
    usbutils

    kdePackages.dolphin
    kdePackages.konsole
    kdePackages.spectacle
  ];

  fonts.packages = [
    fonts.berkeley-mono-nerd-font
  ];
}
