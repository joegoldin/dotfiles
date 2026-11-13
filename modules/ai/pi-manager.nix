# Reusable service and the normal managed Pi profile; host policy stays with the host.
{ inputs, den, ... }:
{
  den.aspects.pi-manager = {
    includes = [ den.aspects.pi ];
    nixos.imports = [ inputs.pi-manager-agent.nixosModules.default ];
  };
}
