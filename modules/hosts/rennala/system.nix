# Base system config (BIOS grub, ssh); nix/nixpkgs settings come from
# den.aspects.nix-settings; the OS account from den.aspects.joe.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.rennala.nixos =
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
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };
    };
}
