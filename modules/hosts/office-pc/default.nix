# office-pc compute/training machine (AMD GPU, ROCm + vllm). Bridged den
# entity: legacy module tree imported as-is, specialArgs injected via
# instantiate + hm extraSpecialArgs (see modules/_lib/legacy-args.nix).
# The offline installer ISO for this machine lives in ./installer.nix.
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
  specialArgs = (import ../../_lib/legacy-args.nix { inherit inputs; }) // {
    hostname = "office-pc";
  };
  overlaysModule = import ../../../hosts/common/system/overlays { inherit inputs; };
  inherit (overlaysModule) unstableOverlays;
in
{
  den.hosts.x86_64-linux.office-pc = {
    users.${meta.username} = { };
    instantiate =
      args:
      inputs.nixpkgs.lib.nixosSystem (
        args // { specialArgs = (args.specialArgs or { }) // specialArgs; }
      );
  };

  den.aspects.office-pc = {
    includes = [ den.aspects.hm-settings ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.nix-index-database.nixosModules.default
        inputs.nix-attic-infra.nixosModules.attic-post-build-hook
        inputs.agenix.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        ../../../hosts/office-pc
      ];

      # ROCm support (AMD GPU)
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final.stdenv.hostPlatform) system;
            config = {
              allowUnfree = true;
              rocmSupport = true;
            };
            overlays = unstableOverlays ++ [
              (import ../../../hosts/common/system/overlays/vllm-rocm.nix)
            ];
          };
        })
      ];

      home-manager = {
        extraSpecialArgs = specialArgs;
        sharedModules = [
          inputs.plasma-manager.homeModules.plasma-manager
        ];
        users.${meta.username} = import ../../../hosts/office-pc/home-manager.nix;
      };

      age.secrets.deepgram_api_key = {
        file = "${inputs.dotfiles-secrets}/deepgram_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.pixeldrain_api_key = {
        file = "${inputs.dotfiles-secrets}/pixeldrain_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.anthropic_api_key = {
        file = "${inputs.dotfiles-secrets}/anthropic_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.attic-token = {
        file = "${inputs.dotfiles-secrets}/attic.token.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.attic-netrc = {
        file = "${inputs.dotfiles-secrets}/attic-netrc.age";
        mode = "0400";
        owner = meta.username;
      };
    };
  };
}
