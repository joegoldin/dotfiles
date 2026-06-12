# drowse (github:figsoda/drowse) — dynamic derivations as the IFD
# replacement. drowse evaluates Nix at *build* time (recursive-nix) instead
# of eval time, giving fine-grained caching without import-from-derivation
# or committed codegen.
#
# Opt-in by design: include `den.aspects.dynamic-derivations` only on hosts
# that should be able to BUILD drowse-based packages. The three extra
# experimental features are required on the machine performing the build
# (and on any remote builder it delegates to). Substituting already-built
# outputs from attic does NOT require them.
#
# Usage from any module (system is in scope wherever pkgs is):
#   drowse = inputs.drowse.lib.${pkgs.stdenv.hostPlatform.system};
#   pkg = drowse.callPackage ./some-package.nix { };
#
# See README.md ("drowse") for the worked mkwindowsapp
# example and the caveats around attic/remote builders.
{ ... }:
{
  den.aspects.dynamic-derivations.os = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
      "dynamic-derivations"
      "recursive-nix"
    ];
  };
}
