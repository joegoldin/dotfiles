{ pkgs, ... }:
# Spotlight/Launchpad trampolines for Nix-installed .app bundles, via our
# Python port of hraban/mac-app-util (modules/flake/_pkgs/mac-app-util).
# The original flake is unusable on macOS 27 (SBCL can't mmap its dynamic
# space), so we replicate its two activation hooks here.
#
# Each hook only acts when the source dir is itself a symlink (pre-25.11
# layout); nix-darwin ≥25.11 copies real .app folders, which Spotlight
# already indexes.
{
  # System-wide apps: /Applications/Nix Apps -> /Applications/Nix Trampolines
  system.activationScripts.postActivation.text = ''
    ${pkgs.mac-app-util}/bin/mac-app-util sync-trampolines \
      "/Applications/Nix Apps" "/Applications/Nix Trampolines"
  '';

  # Per-user (home-manager) apps:
  #   ~/Applications/Home Manager Apps -> ~/Applications/Home Manager Trampolines
  home-manager.sharedModules = [
    (
      { lib, ... }:
      {
        home.activation.trampolineApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.mac-app-util}/bin/mac-app-util sync-trampolines \
            "$HOME/Applications/Home Manager Apps" \
            "$HOME/Applications/Home Manager Trampolines"
        '';
      }
    )
  ];
}
