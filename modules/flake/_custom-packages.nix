# Leaf packages are composed alongside nixpkgs, not inserted into its fixpoint.
{ inputs, pkgs }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
import ./_pkgs pkgs
// {
  # Keep upstream-built artifacts (and their binary-cache identities).
  llm-agents = inputs.llm-agents.packages.${system};
  inherit (inputs.audiomemo.packages.${system}) audiomemo;
  sem = inputs.sem.packages.${system}.default;
  fusion360 = inputs.fusion-360-flake.packages.${system}.fusion360;

  # These end-to-end DERP/magicsock tests time out on loaded builders.
  tailcat = inputs.tailcat.packages.${system}.default.overrideAttrs { doCheck = false; };

  # Preserve mcps.nix's independent pin without importing it again.
  inherit (inputs.mcps.inputs.nixpkgs-unstable.legacyPackages.${system}) github-mcp-server;
  inherit (inputs.mcps.packages.${system}) mcp-language-server;
}
