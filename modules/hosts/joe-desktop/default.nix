# Desktop NixOS workstation (AMD GPU, KDE Plasma).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
  overlaysModule = import ../../flake/_overlays { inherit inputs; };
  inherit (overlaysModule) unstableOverlays;
in
{
  den.hosts.x86_64-linux.joe-desktop.users.${meta.username} = { };

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
        ../../system/_sys/attic.nix
        ../../system/_sys/numtide-cache.nix
        ../../system/_sys/attic-post-build-hook.nix
        ../../system/_sys/howdy.nix
        ../../system/_sys/microvm-host.nix
        ../../system/_sys/oomd.nix
        ../../system/_sys/earlyoom.nix
        ../../system/_sys/1password-browsers.nix
        ../../system/_sys/app-autostart.nix
        ../../system/_sys/gaming.nix
        ./_configuration.nix
        ./_hardware-configuration.nix
        ./_joe-desktop.nix
        ./_wallpaper.nix
        ./_mounts.nix
        ./_uxplay.nix
        # ./_hyprwhspr.nix
        ./_desk-phone.nix
        ./_vban-send.nix
        ./_vban-recv.nix
        ./_data-drives.nix
        ./_nut.nix
      ];

      _module.args.hostname = "joe-desktop";

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
            #   (import ../../flake/_overlays/vllm-rocm.nix)
            # ];
          };
        })
      ];

      home-manager.sharedModules = [
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];

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

    provides.to-users.homeManager = {
      imports = [
        ./_home-manager.nix
        # flake-input hm modules (were imports in modules/home/_hm/default.nix)
        inputs.audiomemo.homeManagerModules.default
        inputs.nix-attic-infra.homeManagerModules.attic-client
        inputs.agent-skills.homeManagerModules.claude
        inputs.agent-skills.homeManagerModules.antigravity
        inputs.agent-skills.homeManagerModules.codex
        inputs.agent-skills.homeManagerModules.agent-skills
      ];
    };
  };
}
