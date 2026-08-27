# volcano-manor compute/training machine (AMD GPU, ROCm + vllm).
# Aspect content lives in the sibling files (system.nix, machine.nix,
# home.nix); the offline installer ISO is ./installer.nix.
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.volcano-manor.users.${meta.username} = { };

  den.aspects.volcano-manor = {
    includes = [
      den.aspects.nix-settings
      # system features
      den.aspects.binary-caches
      den.aspects.attic-post-build-hook
      den.aspects.numtide-cache
      den.aspects.app-autostart
      den.aspects.filesystem-tools
      den.aspects.gaming
      den.aspects.howdy
      den.aspects."1password-browsers"
      # home features (projected onto users via the host-aspects battery)
      den.aspects.home-baseline
      den.aspects.default-apps
      den.aspects.workstation-packages
      den.aspects.linux-workstation-packages
      den.aspects.zen
      den.aspects.plasma
      den.aspects.zed
      den.aspects.ghostty
      den.aspects.mouse-actions
    ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        ./_disk-config.nix
        ./_hardware-configuration.nix
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
      # Provider keys for pi (modules/ai/pi.nix). anthropic_api_key above is
      # shared with other tooling; these two exist only for pi's
      # environment.<NAME>.file wiring, which cats them at launch.
      age.secrets.openai_api_key = {
        file = "${inputs.dotfiles-secrets}/openai_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.openrouter_api_key = {
        file = "${inputs.dotfiles-secrets}/openrouter_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.umans_api_key = {
        file = "${inputs.dotfiles-secrets}/umans_api_key.age";
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
