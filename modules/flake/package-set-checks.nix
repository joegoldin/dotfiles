# Evaluation-only invariants: requesting drvPath exercises these assertions
# without building the check or any application.
{ inputs, packageSets, ... }:
{
  perSystem =
    {
      pkgs,
      customPackages,
      system,
      ...
    }:
    {
      checks.package-sets =
        assert !(pkgs ? llm-agents);
        assert !(pkgs ? audiomemo);
        assert pkgs.unstable.hello.drvPath == packageSets.${system}.unstable.hello.drvPath;
        assert customPackages.sem.drvPath == inputs.sem.packages.${system}.default.drvPath;
        assert customPackages.audiomemo.drvPath == inputs.audiomemo.packages.${system}.audiomemo.drvPath;
        assert customPackages.tailcat.doCheck == false;
        assert pkgs.config.allowUnfree && pkgs.config.allowUnsupportedSystem;
        pkgs.runCommand "package-set-tests" { } ''
          touch "$out"
        '';
    };
}
