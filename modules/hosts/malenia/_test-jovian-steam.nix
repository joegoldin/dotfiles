# Evaluate against the real host to catch conflicting package definitions as well
# as accidentally replacing Jovian's Steam wrapper with the regular package.
# From the repository root:
# nix eval --json --impure --expr 'let flake = builtins.getFlake (toString ./.); in import ./modules/hosts/malenia/_test-jovian-steam.nix { configuration = flake.nixosConfigurations.malenia; }'
{ configuration }:
let
  actual = configuration.config.programs.steam.package;
  # NixOS also adds graphics libraries and compatibility tools to this option.
  expected = configuration.options.programs.steam.package.apply (
    configuration.pkgs.jovianPackages.steam.override {
      extraProfile = ''
        unset DOTNET_ROOT DOTNET_ROOT_X64 DOTNET_ROOT_X86 'DOTNET_ROOT(x86)'
      '';
    }
  );
in
assert actual.drvPath == expected.drvPath;
{
  package = actual.drvPath;
  jovianDotnetCleanup = true;
}
