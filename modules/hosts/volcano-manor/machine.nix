# hosts/volcano-manor/volcano-manor.nix
# Specific configuration for volcano-manor compute machine
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  dotfiles-assets = inputs.dotfiles-assets;
  username = meta.username;
in
{
  den.aspects.volcano-manor.nixos =
    {
      pkgs,
      lib,
      ...
    }:
    let
      fonts = import ../../_data/fonts { inherit pkgs lib dotfiles-assets; };
      streamcontroller-rules = pkgs.writeTextFile {
        name = "99-streamcontroller-osplugin.rules";
        text = ''
          KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", GROUP="input", MODE="0660"
        '';
        destination = "/etc/udev/rules.d/99-streamcontroller-osplugin.rules";
      };
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
        displayManager = {
          sddm.enable = true;
          autoLogin = {
            enable = true;
            user = "${username}";
          };
        };
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

      # Open RDP port for krdp
      networking.firewall.allowedTCPPorts = [ 3389 ];

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

      services.udev.packages = [
        streamcontroller-rules
        (import ../../system/_streamcontroller.nix { inherit pkgs; }).package
      ];

      environment.systemPackages = with pkgs; [
        clinfo
        mesa-demos
        btop-rocm
        pciutils
        usbutils

        kdePackages.ark
        kdePackages.dolphin
        kdePackages.gwenview
        kdotool
        kdePackages.konsole
        kdePackages.krdp
        kdePackages.spectacle
      ];

      fonts.packages = [
        fonts.berkeley-mono-nerd-font
      ];
    };
}
