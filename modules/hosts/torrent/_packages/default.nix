# Mac-ONLY home packages; only things tied to this platform belong here
# (Xcode/Swift tooling, macOS VMs, iTerm2, brew-replacement build libs).
# Anything cross-platform goes in modules/home/_hm/packages/workstation.nix
# (workstations) or modules/home/_hm/packages/default.nix (all hosts).
# GUI apps come from Homebrew casks (../homebrew.nix), not nixpkgs.
#
# Dropped during the brew->nix migration (no nixpkgs package):
#   xcode-build-server, jenv, lporg, assemblyai, clippy (neilberkman),
#   ocr (schappim), skip (skiptools), swiftly, jj
{ pkgs, lib, ... }:
let
  packageGroups = with pkgs; {
    cli = [
      fastlane
      iterm2-terminal-integration
      softnet # tart VM networking (cirruslabs)
      swift-format
      swiftlint
      tart
      xcbeautify
    ];

    # Brew-replacement C libs kept on PATH/profile for local mac builds.
    build-libs = [
      autoconf269 # autoconf@2.69
      expat
      portaudio
      tcl # tcl-tk
      tk # tcl-tk
    ];
  };
in
{
  imports = [ ./audiomemo.nix ];

  home.packages = lib.flatten (lib.attrValues packageGroups);
}
