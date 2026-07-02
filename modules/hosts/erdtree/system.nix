# Base system config (BIOS grub, ssh, fail2ban). Bare-metal dedicated server:
# confirm the real boot mode (BIOS vs UEFI) and disk device at provision time
# and adjust boot.loader + _disk-config.nix accordingly.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.erdtree.nixos =
    { lib, pkgs, ... }:
    {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # GRUB BIOS boot — PLACEHOLDER device. Confirm /dev/sda vs nvme and
      # BIOS vs UEFI on the real box before deploy (see _disk-config.nix).
      boot.loader.grub = {
        enable = lib.mkForce true;
        devices = lib.mkForce [ "/dev/sda" ];
      };

      users.users.${meta.username}.extraGroups = [
        "audio"
        "video"
        "docker"
      ];

      programs = {
        zsh.enable = true;
        fish.enable = true;
        # ld for vscode server
        nix-ld = {
          enable = true;
          package = pkgs.nix-ld;
        };
      };

      environment.systemPackages = with pkgs; [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        git
        unstable.sbctl
        wget
      ];

      services.openssh = {
        enable = true;
        settings = {
          # Opinionated: forbid root login through SSH.
          PermitRootLogin = "no";
          # Opinionated: use keys only.
          PasswordAuthentication = false;
        };
      };

      # Brute-force protection for the public host (default sshd jail).
      services.fail2ban = {
        enable = true;
        bantime = "1h";
        bantime-increment = {
          enable = true;
          maxtime = "24h";
        };
      };
    };
}
