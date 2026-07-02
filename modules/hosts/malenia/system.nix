# Base system config; nix/nixpkgs settings come from den.aspects.nix-settings
# (gc cadence and optimise diverge below); OS account from den.aspects.joe.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.malenia.nixos =
    { pkgs, ... }:
    {
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      # Deck-specific nix tuning (deltas from den.aspects.nix-settings)
      nix.settings.auto-optimise-store = true;
      nix.settings.builders-use-substitutes = true;
      nix.gc.options = "--delete-older-than 14d";

      time.timeZone = "America/Los_Angeles";

      networking.networkmanager.enable = true;

      users.users.${meta.username}.extraGroups = [
        "audio"
        "video"
        "input"
      ];

      programs = {
        fish.enable = true;
        nix-ld.enable = true;
        nix-index-database.comma.enable = true;
      };

      environment.systemPackages = with pkgs; [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        flatpak
        git
        wget
        maliit-keyboard
      ];

      # KDE Plasma desktop (for switching out of Game Mode)
      services.desktopManager.plasma6.enable = true;

      # Strip default KDE bloat; keep it lean for a gaming device
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        discover
        elisa
        kate
        khelpcenter
        kmailtransport
        konsole
        krdp
        kwallet
        kwallet-pam
        oxygen
        plasma-welcome
        print-manager
      ];

      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };

      services.tailscale = {
        enable = true;
        package = pkgs.unstable.tailscale;
      };
    };
}
