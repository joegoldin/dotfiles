# Base system config (BIOS grub, ssh, fail2ban); nix/nixpkgs settings come from
# den.aspects.nix-settings; the OS account from den.aspects.joe.
# VPS assumed /dev/vda + BIOS (ColoCrossing/RackNerd-style); confirm the disk
# device and boot mode at provision and adjust _disk-config.nix if different.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.siofra.nixos =
    { lib, pkgs, ... }:
    {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # Use GRUB boot loader for BIOS boot
      boot.loader.grub = {
        enable = lib.mkForce true;
        devices = lib.mkForce [ "/dev/vda" ];
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
          # Forbid root SSH on the booted system — admin is joe + passwordless
          # sudo, and the initrd LUKS-unlock uses its own separate sshd. (A
          # re-install targets a fresh/rescue image, or nixos-anywhere over joe@.)
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
