# Pre-commit checks + the devShell that installs them.
{ inputs, ... }:
{
  perSystem =
    { system, config, ... }:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      # These hooks need no compiler. On macOS, stdenv's SDK and xcrun would
      # otherwise mask the manually installed Xcode and its iOS SDKs.
      mkShell = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.mkShellNoCC else pkgs.mkShell;
    in
    {
      checks.pre-commit-check = inputs.git-hooks.lib.${system}.run {
        src = ../../.;
        hooks = {
          nixfmt.enable = true;
          check-yaml.enable = true;
          end-of-file-fixer.enable = true;
          gitleaks.enable = true;
        };
      };

      checks.dev-shell-toolchain =
        assert config.devShells.default.stdenv.hasCC == !pkgs.stdenv.hostPlatform.isDarwin;
        pkgs.runCommand "dev-shell-toolchain" { } ''
          touch "$out"
        '';

      devShells.default = mkShell {
        inherit (config.checks.pre-commit-check) shellHook;
        buildInputs = config.checks.pre-commit-check.enabledPackages;
      };
    };
}
