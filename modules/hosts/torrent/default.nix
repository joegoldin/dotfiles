# torrent (aarch64-darwin). Aspect content lives in the sibling
# files (system.nix, mac-system.nix, apps.nix, homebrew.nix,
# mac-app-util.nix, home.nix).
#
# den's stock darwin builder expects inputs.darwin; our input is named
# nix-darwin, so instantiate is set explicitly.
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.aarch64-darwin.torrent = {
    users.${meta.username} = { };
    instantiate = inputs.nix-darwin.lib.darwinSystem;
  };

  den.aspects.torrent = {
    includes = [
      den.aspects.nix-settings
      den.aspects.binary-caches
      den.aspects.numtide-cache
      # home features (projected onto users via the host-aspects battery)
      den.aspects.home-baseline
      den.aspects.zed
      den.aspects.zen
      den.aspects.workstation-packages
    ];

    darwin = {
      imports = [
        inputs.nix-index-database.darwinModules.default
        inputs.nix-homebrew.darwinModules.nix-homebrew
        # vfkit-based Linux builder (enabled below, currently kept off for bootstrap)
        inputs.virby.darwinModules.default
        inputs.agenix.darwinModules.default
      ];

      age.identityPaths = [ "/var/lib/agenix/identity" ];
      age.secrets.attic-netrc = {
        file = "${inputs.dotfiles-secrets}/attic-netrc.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.gws-credentials = {
        file = "${inputs.dotfiles-secrets}/gws-credentials.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.kanary-notion-api-token = {
        file = "${inputs.dotfiles-secrets}/kanary-notion-api-token.age";
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
        # 8 build jobs (maxJobs = cores) on the default 6GiB thrash/OOM on heavy
        # aarch64 builds (GTK, Zig). This Mac has 24GiB and virby is on-demand,
        # so give it more headroom (~1.25GiB/job).
        memory = "10GiB";
      };
    };
  };
}
