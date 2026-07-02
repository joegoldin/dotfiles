# Base system config (UEFI systemd-boot, ssh, fail2ban). erdtree is a UEFI Dell
# server; the ESP + LUKS root layout lives in _disk-config.nix.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.erdtree.nixos =
    { lib, pkgs, ... }:
    {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # UEFI boot via systemd-boot (ESP mounted at /boot by disko).
      boot.loader = {
        systemd-boot.enable = lib.mkForce true;
        efi.canTouchEfiVariables = true;
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
