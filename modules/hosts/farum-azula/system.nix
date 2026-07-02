# Base system config (boot, ssh, fail2ban); nix/nixpkgs settings come from
# den.aspects.nix-settings; the OS account from den.aspects.joe.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.farum-azula.nixos =
    { lib, pkgs, ... }:
    {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # Use the systemd-boot EFI boot loader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

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

      # Brute-force protection for the public bastion (default sshd jail).
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
