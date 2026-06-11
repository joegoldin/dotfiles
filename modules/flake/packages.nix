# Custom packages, accessible through 'nix build .#<name>', 'nix shell', etc.
# (was basePackages in the legacy flake.nix; additionalPackages was empty).
{ inputs, config, ... }:
let
  flakeOverlays = config.flake.overlays;
in
{
  perSystem =
    { system, ... }:
    {
      packages = import ./_pkgs (
        import inputs.nixpkgs {
          inherit system;
          overlays = builtins.attrValues flakeOverlays;
          config.allowUnfree = true;
        }
      );
    };
}
