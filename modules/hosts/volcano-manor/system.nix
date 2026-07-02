# Base system config (lanzaboote secure boot, ROCm unstable overlay);
# nix/nixpkgs settings come from den.aspects.nix-settings (cores delta
# below); OS account from den.aspects.joe.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  overlaysModule = import ../../flake/_overlays { inherit inputs; };
  inherit (overlaysModule) unstableOverlays;
in
{
  den.aspects.volcano-manor.nixos =
    { lib, pkgs, ... }:
    {
      # Lanzaboote replaces systemd-boot for secure boot
      boot = {
        loader = {
          systemd-boot.enable = lib.mkForce false;
          efi.canTouchEfiVariables = true;
        };
        lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
        };
      };

      # Enable aarch64 cross-compilation via QEMU
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      # ROCm support (AMD GPU): rebuild the `unstable` package set with
      # rocmSupport + the vllm-rocm overlay. Later overlays win, so this
      # replaces the stock pkgs.unstable from the shared overlay set.
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final.stdenv.hostPlatform) system;
            config = {
              allowUnfree = true;
              rocmSupport = true;
            };
            overlays = unstableOverlays ++ [
              (import ../../flake/_overlays/vllm-rocm.nix)
            ];
          };
        })
      ];

      # Compute-box nix tuning (deltas from den.aspects.nix-settings)
      nix.settings.builders-use-substitutes = true;
      nix.settings.cores = 20;

      time.timeZone = "America/Los_Angeles";

      networking.networkmanager.enable = true;

      users.users.${meta.username}.extraGroups = [
        "audio"
        "video"
        "docker"
        "input"
      ];

      programs = {
        zsh.enable = true;
        fish.enable = true;
        _1password.enable = true;
        _1password-gui = {
          enable = true;
          polkitPolicyOwners = [ meta.username ];
        };
        nix-ld.enable = true;
        nix-index-database.comma.enable = true;
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

      services.tailscale.enable = true;

      services.locate = {
        enable = true;
      };
    };
}
