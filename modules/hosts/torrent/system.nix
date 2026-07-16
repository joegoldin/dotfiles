# Darwin base system; nix/nixpkgs settings come from den.aspects.nix-settings
# (mac-specific deltas below); OS account from den.aspects.joe.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.torrent.darwin =
    { lib, pkgs, ... }:
    {
      system.stateVersion = 5;

      nixpkgs = {
        hostPlatform = lib.mkDefault "aarch64-darwin";
        overlays = [ inputs.brew-nix.overlays.default ];
        flake = {
          setFlakeRegistry = false;
          setNixPath = false;
        };
      };

      nix = {
        enable = true;
        settings = {
          # 2 parallel jobs × 6 threads each = 12 max threads.
          max-jobs = 2;
          cores = 6;

          # Enable building for x86_64-darwin on aarch64-darwin
          extra-platforms = [
            "x86_64-darwin"
            "aarch64-darwin"
          ];
        };
      };

      ids.uids.nixbld = lib.mkForce 350;

      programs = {
        bash.enable = true;
        zsh.enable = true;
        fish.enable = true;
        nix-index-database.comma.enable = true;
      };

      environment.systemPackages = with pkgs; [
        git
        jdk
        nh
        nixos-rebuild-ng
        wget
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        # darwin.xcode_16_3  # TODO: enable this when available in nixpkgs
      ];

      # nh uses NH_DARWIN_FLAKE to locate the flake for darwin commands
      environment.variables.NH_DARWIN_FLAKE = "/Users/${meta.username}/dotfiles";
    };
}
