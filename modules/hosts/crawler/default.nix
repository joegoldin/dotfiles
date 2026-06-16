# crawler — Raspberry Pi 3B+ SBC for a small AI quadruped robot. A native den
# entity that swaps the system builder to nixos-raspberrypi's nixosSystem,
# which merges specialArgs, appends our modules after its RPi modules, and sets
# nixpkgs.hostPlatform = aarch64-linux. Aspect content is split across
# system.nix / net.nix / robot.nix (merged by name, like cloud-proxy's
# default.nix + services.nix).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.aarch64-linux.crawler = {
    users.${meta.username} = { };
    instantiate = inputs.nixos-raspberrypi.lib.nixosSystem;
  };

  den.aspects.crawler = {
    includes = [
      den.aspects.nix-settings
      den.aspects.attic # binary-cache substituter + hm attic-client
      den.aspects.numtide-cache
      den.aspects.shell-tools # direnv, skim, zellij (lean)
      den.aspects.claude # Claude Code (claude-nix) + agent-skills
    ];

    # Claude only — we do NOT want the codex/antigravity binaries here. But the
    # shared agent-skills module's per-agent MCP fan-out references the
    # programs.codex-nix / programs.antigravity-cli-nix option *paths*
    # (mkIf can't suppress a missing option path), so importing just the claude
    # aspect errors with "option does not exist". Import those two agents'
    # home-manager modules to DECLARE their options (programs stay disabled by
    # default, so nothing is installed), which satisfies the fan-out.
    homeManager =
      { ... }:
      {
        imports = [
          inputs.agent-skills.homeManagerModules.codex
          inputs.agent-skills.homeManagerModules.antigravity
        ];
      };

    nixos =
      { lib, ... }:
      {
        imports =
          (with inputs.nixos-raspberrypi.nixosModules; [
            raspberry-pi-3.base
            sd-image
          ])
          ++ [
            inputs.agenix.nixosModules.default
            inputs.nix-index-database.nixosModules.default
          ];

        # Reuse the SSH host key as the agenix identity. It is pre-generated and
        # injected into the image (see the plan's secrets + flash tasks), so
        # secrets decrypt on the first headless boot. attic-token is read by the
        # hm attic-client at /run/agenix/attic-token; attic-netrc by the attic
        # `os` aspect.
        age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        age.secrets.attic-netrc.file = "${inputs.dotfiles-secrets}/attic-netrc.age";
        age.secrets.attic-token = {
          file = "${inputs.dotfiles-secrets}/attic.token.age";
          mode = "0400";
          owner = meta.username;
        };

        # Build a raw (uncompressed) .img so the flash recipe can loop-mount the
        # ext4 root and inject the host key without a zstd round-trip.
        sdImage.compressImage = false;

        # The Pi boots from the ext4 SD card and never touches ZFS, but the
        # sd-image base profile pulls ZFS into supportedFilesystems. Drop it:
        # avoids building zfs-kernel/zfs-user (slow + closure/RAM cost on a 1GB
        # RPi3, and the flaky attic zfs-user NAR) and silences the 26.11
        # boot.zfs.forceImportRoot warning.
        boot.supportedFilesystems.zfs = lib.mkForce false;

        # Fresh install on 26.05 (overrides den's 24.11 default).
        system.stateVersion = lib.mkForce "26.05";
      };
  };
}
