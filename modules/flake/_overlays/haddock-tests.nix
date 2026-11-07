{ pkgs }:
let
  affected = [
    "crypton-connection"
    "crypton-x509-store"
    "djot"
    "fsnotify"
    "hslua-cli"
    "hslua-typing"
    "servant"
    "skylighting"
    "wai-cors"
  ];
  serialDocumentation =
    name:
    let
      package = pkgs.haskellPackages.${name};
    in
    pkgs.lib.hasSuffix "--haddock-option=-j1\n\nrunHook postHaddock\n" package.haddockPhase
    && pkgs.lib.hasInfix "--haddock-option=-j$NIX_BUILD_CORES" package.haddockPhase
    && pkgs.lib.hasInfix "haddock --html" package.haddockPhase
    && pkgs.lib.hasInfix "-j$NIX_BUILD_CORES" package.setupCompilerEnvironmentPhase;
in
assert builtins.all serialDocumentation affected;
# Do not change unrelated libraries or disable package test suites.
assert !(pkgs.lib.hasInfix "--haddock-option=-j1" pkgs.haskellPackages.aeson.haddockPhase);
assert pkgs.haskellPackages.djot.doCheck;
true
