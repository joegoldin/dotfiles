# Desktop NixOS workstation (AMD GPU, KDE Plasma). Bridged den entity:
# legacy module tree imported as-is, specialArgs injected via instantiate +
# hm extraSpecialArgs (see modules/_lib/legacy-args.nix).
{ inputs, den, ... }:
let
  meta = import ../_lib/meta.nix;
  specialArgs = (import ../_lib/legacy-args.nix { inherit inputs; }) // {
    hostname = "joe-desktop";
  };
  overlaysModule = import ../../hosts/common/system/overlays { inherit inputs; };
  inherit (overlaysModule) unstableOverlays;
in
{
  den.hosts.x86_64-linux.joe-desktop = {
    users.${meta.username} = { };
    instantiate =
      args:
      inputs.nixpkgs.lib.nixosSystem (
        args // { specialArgs = (args.specialArgs or { }) // specialArgs; }
      );
  };

  den.aspects.joe-desktop = {
    includes = [ den.aspects.hm-settings ];

    nixos = {
      imports = [
        inputs.nix-index-database.nixosModules.default
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.nix-attic-infra.nixosModules.attic-post-build-hook
        inputs.agenix.nixosModules.default
        inputs.desk-phone.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        # > Our main nixos configuration <
        ../../hosts/nixos
      ];

      # ROCm support only on desktop (has AMD GPU)
      # temporarily disabled — rocmSupport + vllm-rocm = 15h build
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final.stdenv.hostPlatform) system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
              # rocmSupport = true;
            };
            overlays = unstableOverlays;
            # overlays = unstableOverlays ++ [
            #   (import ../../hosts/common/system/overlays/vllm-rocm.nix)
            # ];
          };
        })
      ];

      home-manager = {
        extraSpecialArgs = specialArgs;
        sharedModules = [
          inputs.plasma-manager.homeModules.plasma-manager
          inputs.nix-flatpak.homeManagerModules.nix-flatpak
        ];
        users.${meta.username} = import ../../hosts/nixos/home-manager.nix;
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
      age.secrets.elevenlabs_api_key = {
        file = "${inputs.dotfiles-secrets}/elevenlabs_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.wakapi_api_key = {
        file = "${inputs.dotfiles-secrets}/wakapi_api_key.age";
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
      age.secrets.atuin_key = {
        file = "${inputs.dotfiles-secrets}/atuin_key.age";
        mode = "0400";
        owner = meta.username;
      };
    };
  };
}
