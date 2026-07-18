# Desktop NixOS workstation (AMD GPU, KDE Plasma).
# Aspect content lives in the sibling files (system.nix, machine.nix,
# home.nix, wallpaper.nix, …); they all merge into den.aspects.elphael.
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.elphael.users.${meta.username} = { };

  den.aspects.elphael = {
    includes = [
      den.aspects.nix-settings
      den.aspects.dynamic-derivations
      # system features
      den.aspects.binary-caches
      den.aspects.attic-post-build-hook
      den.aspects.numtide-cache
      den.aspects.howdy
      den.aspects.microvm-host
      den.aspects.oomd
      den.aspects.earlyoom
      den.aspects."1password-browsers"
      den.aspects.app-autostart
      den.aspects.gaming
      # home features (projected onto users via the host-aspects battery)
      den.aspects.home-baseline
      den.aspects.plasma
      den.aspects.zen
      den.aspects.workstation-packages
      den.aspects.linux-workstation-packages
      den.aspects.ghostty
      den.aspects.zed
      den.aspects.default-apps
      den.aspects.mouse-actions
      # den.aspects.chatgpt-desktop  # blocked: chatgpt-desktop-linux patches
      # don't support ChatGPT.dmg 26.715 yet (upstream last updated 2026-07-10,
      # DMG moved to 26.715 on 2026-07-17). Re-enable once
      # EricKrouss/chatgpt-desktop-linux ships patch support for 26.715+.
    ];

    nixos = {
      imports = [
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.agenix.nixosModules.default
        inputs.desk-phone.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        ./_hardware-configuration.nix
        # ./_hyprwhspr.nix  # disabled: underscored so import-tree skips it
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
      age.secrets.umans_api_key = {
        file = "${inputs.dotfiles-secrets}/umans_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      # Authentik API token for the garnix authentik-provision helper. Read via
      # `authentik-provision --token-file /run/agenix/authentik-api-token`.
      age.secrets.authentik-api-token = {
        file = "${inputs.dotfiles-secrets}/authentik-api-token.age";
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
      age.secrets.kanary-notion-api-token = {
        file = "${inputs.dotfiles-secrets}/kanary-notion-api-token.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.gws-credentials = {
        file = "${inputs.dotfiles-secrets}/gws-credentials.age";
        mode = "0400";
        owner = meta.username;
      };
    };
  };
}
