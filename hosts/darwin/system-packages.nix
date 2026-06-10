{ pkgs, ... }:
{
  ###########################################################################
  #
  #  CLI tools migrated off Homebrew (former `homebrew.brews` + manual
  #  installs) -> nixpkgs. Homebrew keeps only GUI casks (homebrew.nix) and
  #  `mas` for Mac App Store apps (apps.nix).
  #
  #  Not listed here because home-manager already provides them
  #  (hosts/common/home/packages.nix & friends): act, asciinema, aws-cli
  #  (awscli2 wrapper), direnv, flyctl, gh (programs.gh), git-lfs
  #  (programs.git.lfs), glow, gum, helm/helmfile-with-plugins, httpie, k9s,
  #  kubectx, python (./python), tesseract, wget. htop -> btop.
  #
  #  Dropped entirely (no nixpkgs package; uninstalled from brew):
  #    xcode-build-server, jenv, lporg, assemblyai, clippy (neilberkman),
  #    ocr (schappim), skip (skiptools), swiftly, jj
  #
  ###########################################################################

  environment.systemPackages = with pkgs; [
    asdf-vm # asdf
    autoconf269 # autoconf@2.69
    btop
    cloudflared
    cmake
    croc
    dive
    docker-compose
    entr
    expat
    fastfetch # neofetch (removed upstream)
    fastlane
    fontforge
    ghostscript
    gradle
    helmfile
    inetutils # telnet
    kubefwd
    mas # Mac App Store CLI — backs homebrew.masApps (apps.nix)
    mysql84 # mysql
    nodejs # node
    okteto
    ollama
    pidgin
    portaudio
    profanity
    protobuf
    redis
    ruby
    saml2aws
    scrcpy
    silver-searcher # the_silver_searcher
    softnet # tart VM networking (cirruslabs)
    sops
    sshpass
    stern
    swift-format
    swiftlint
    tailspin
    tart
    tcl # tcl-tk
    terraform
    timg
    tk # tcl-tk
    universal-ctags
    visidata
    watchman
    xcbeautify

    python3Packages.docutils # docutils
    python3Packages.keyring # keyring
    python3Packages.virtualenv # virtualenv
  ];
}
