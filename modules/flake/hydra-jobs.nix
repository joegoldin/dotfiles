{ config, lib, ... }:
{
  # Preserve the Garnix build set: Linux systems only, excluding scarab.
  flake.hydraJobs = lib.mapAttrs (_: host: host.config.system.build.toplevel) (
    removeAttrs config.flake.nixosConfigurations [ "scarab" ]
  );
}
