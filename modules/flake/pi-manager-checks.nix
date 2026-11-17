{
  config,
  inputs,
  lib,
  ...
}:
{
  perSystem = { pkgs, system, ... }: {
    checks = lib.optionalAttrs (system == "x86_64-linux") (
      let
        host = config.flake.nixosConfigurations.rennala.config;
        template = host.system.build.pi-manager-controller-template;
        # Inspect the generated JSON without realizing its referenced packages.
        configuration = builtins.fromJSON (builtins.unsafeDiscardStringContext template.value);
        pi = inputs.agent-skills.inputs.pi-nix.packages.${system}.coding-agent-bun;
      in
      {
        pi-manager-template =
          assert configuration.core.pi.version == pi.version;
          assert !configuration.core.dispatchEnabled;
          pkgs.runCommand "pi-manager-template-tests" { } ''
            touch "$out"
          '';
      }
    );
  };
}
