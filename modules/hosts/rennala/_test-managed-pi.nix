# Run after building system.build.pi-manager-controller-template:
# nix eval --json --impure --expr 'let flake = builtins.getFlake (toString ./.); in import ./modules/hosts/rennala/_test-managed-pi.nix { inherit flake; }'
{ flake }:
let
  configuration = flake.nixosConfigurations.rennala.config;
  template = builtins.fromJSON (
    builtins.unsafeDiscardStringContext (
      builtins.readFile configuration.system.build.pi-manager-controller-template
    )
  );
  expected = flake.inputs.agent-skills.inputs.pi-nix.packages.x86_64-linux.default.version;
in
assert template.core.pi.version == expected;
assert !template.core.dispatchEnabled;
{
  piVersion = expected;
  dispatchEnabled = template.core.dispatchEnabled;
}
