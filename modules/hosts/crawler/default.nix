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
    ];

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

        # Fresh install on 26.05 (overrides den's 24.11 default).
        system.stateVersion = lib.mkForce "26.05";
      };
  };
}
