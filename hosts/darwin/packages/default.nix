# Mac-only home packages. CLI tools shared with linux workstations live in
# hosts/common/home/packages/workstation.nix; tools shared with all hosts in
# hosts/common/home/packages/default.nix.
#
# Dropped during the brew->nix migration (no nixpkgs package):
#   xcode-build-server, jenv, lporg, assemblyai, clippy (neilberkman),
#   ocr (schappim), skip (skiptools), swiftly, jj
{ pkgs, ... }:
{
  imports = [ ./audiomemo.nix ];

  home.packages = with pkgs; [
    asdf-vm # asdf
    autoconf269 # autoconf@2.69
    claude-container # needs native build, no QEMU
    expat
    fastlane
    fontforge
    ghostscript
    gradle
    inetutils # telnet
    iterm2-terminal-integration
    mysql84 # mysql
    okteto
    ollama
    pidgin
    portaudio
    profanity
    redis
    ruby
    saml2aws
    scrcpy
    shopt-script
    silver-searcher # the_silver_searcher
    softnet # tart VM networking (cirruslabs)
    swift-format
    swiftlint
    tailspin
    tart
    tcl # tcl-tk
    terraform
    tk # tcl-tk
    xcbeautify

    python3Packages.docutils # docutils
    python3Packages.keyring # keyring
    python3Packages.virtualenv # virtualenv
  ];
}
