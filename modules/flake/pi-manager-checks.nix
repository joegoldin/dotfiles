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
        meta = import ../_lib/meta.nix;
        installedPi = host.home-manager.users.${meta.username}.programs.pi.coding-agent.installedPackage;
      in
      {
        pi-manager-template =
          assert configuration.core.pi.version == pi.version;
          assert !configuration.core.dispatchEnabled;
          pkgs.runCommand "pi-manager-template-tests" { } ''
            # Metadata agreement alone misses a drifted or overridden profile wrapper.
            export HOME="$TMPDIR/home"
            export XDG_CONFIG_HOME="$HOME/.config"
            export XDG_CACHE_HOME="$HOME/.cache"
            export XDG_DATA_HOME="$HOME/.local/share"
            export XDG_RUNTIME_DIR="$TMPDIR/runtime"
            export PI_CODING_AGENT_DIR="$HOME/.pi/agent"
            mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
            chmod 700 "$HOME" "$XDG_RUNTIME_DIR"
            actual="$(${lib.getExe installedPi} --version)"
            test "$actual" = ${lib.escapeShellArg configuration.core.pi.version}
            touch "$out"
          '';
      }
    );
  };
}
