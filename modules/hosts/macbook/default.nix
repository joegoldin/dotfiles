# Joes-MacBook-Pro (aarch64-darwin).
# den's stock darwin builder expects inputs.darwin; our input is named
# nix-darwin, so instantiate is set explicitly.
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.aarch64-darwin.Joes-MacBook-Pro = {
    users.${meta.username} = { };
    instantiate = inputs.nix-darwin.lib.darwinSystem;
  };

  den.aspects.Joes-MacBook-Pro = {
    includes = [ den.aspects.hm-settings ];

    darwin = {
      imports = [
        inputs.nix-index-database.darwinModules.default
        inputs.nix-homebrew.darwinModules.nix-homebrew
        # vfkit-based Linux builder (enabled below, currently kept off for bootstrap)
        inputs.virby.darwinModules.default
        inputs.agenix.darwinModules.default
        # > Our main darwin configuration <
        ./_configuration.nix
      ];

      _module.args.hostname = "Joes-MacBook-Pro";

      age.identityPaths = [ "/var/lib/agenix/identity" ];
      age.secrets.attic-netrc = {
        file = "${inputs.dotfiles-secrets}/attic-netrc.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.attic-token = {
        file = "${inputs.dotfiles-secrets}/attic.token.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.wakapi_api_key = {
        file = "${inputs.dotfiles-secrets}/wakapi_api_key.age";
        mode = "0400";
      };
      age.secrets.atuin_key = {
        file = "${inputs.dotfiles-secrets}/atuin_key.age";
        mode = "0400";
        owner = meta.username;
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
      age.secrets.elevenlabs_api_key = {
        file = "${inputs.dotfiles-secrets}/elevenlabs_api_key.age";
        mode = "0400";
        owner = meta.username;
      };

      # vfkit-based Linux builder. The stock nix.linux-builder is kept off;
      # it was only used to bootstrap this rebuild (it builds virby's VM
      # image, then virby takes over as the aarch64-/x86_64-linux builder).
      nix.linux-builder.enable = false;
      services.virby = {
        enable = true;
        # Start the VM on demand and power it down after idle (parity with
        # the old rosetta-builder onDemand setup).
        onDemand.enable = true;
        # Build x86_64-linux via Rosetta translation (aarch64-darwin only).
        rosetta = true;
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
