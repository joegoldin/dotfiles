# Pre-commit checks + the devShell that installs them (verbatim from the
# legacy flake.nix checks/devShells outputs).
{ inputs, ... }:
{
  perSystem =
    { system, config, ... }:
    {
      checks.pre-commit-check = inputs.git-hooks.lib.${system}.run {
        src = ../../.;
        hooks = {
          nixfmt.enable = true;
          check-yaml.enable = true;
          end-of-file-fixer.enable = true;
          gitleaks = {
            enable = true;
            name = "gitleaks";
            entry = "${inputs.nixpkgs.legacyPackages.${system}.gitleaks}/bin/gitleaks detect --source . -v";
          };
        };
      };

      devShells.default = inputs.nixpkgs.legacyPackages.${system}.mkShell {
        inherit (config.checks.pre-commit-check) shellHook;
        buildInputs = config.checks.pre-commit-check.enabledPackages;
      };
    };
}
