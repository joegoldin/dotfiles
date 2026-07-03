# Base system config (UEFI systemd-boot, ssh). A LAN home-automation box, so no
# fail2ban (not public); it must auto-boot unattended after a power blip, so no
# disk encryption. nix/nixpkgs settings come from den.aspects.nix-settings.
_: {
  den.aspects.melina.nixos =
    { lib, pkgs, ... }:
    {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # UEFI boot via systemd-boot (ESP mounted at /boot by disko).
      boot.loader = {
        systemd-boot.enable = lib.mkForce true;
        efi.canTouchEfiVariables = true;
      };

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
        git
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
