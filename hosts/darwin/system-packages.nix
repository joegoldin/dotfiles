{ pkgs, ... }:
let
  # GUI casks whose upstream Homebrew cask ships no sha256 ("no_check" / null).
  # brew-nix can't build those without an explicit hash, so pin it here. Hashes
  # were prefetched from each cask's download URL (`nix store prefetch-file`).
  pinnedCasks =
    let
      pin =
        name: hash:
        pkgs.brewCasks.${name}.overrideAttrs (old: {
          src = pkgs.fetchurl {
            url = builtins.head old.src.urls;
            inherit hash;
          };
        });
    in
    [
      (pin "soundsource" "sha256-Bb/IZSnwSij3Ok4y3JCjlbkF+iumWZaVmnOBgo6FsZA=")
      (pin "roon" "sha256-l/B0ElpcYbs1DCjHWtV2mVUuh1dnF093Y6bbmddsngo=")
      (pin "daisydisk" "sha256-ES0zllLFK31dsdud8RaJuTRdpQJjN3/2a/1PM6ZxBt4=")
      (pin "google-chrome" "sha256-cQlNcoRcxFKswIfON3Cmo4MiEfrTilhaXVkpjKvl3Xc=")
    ];
in
{
  ###########################################################################
  #
  #  System packages migrated off Homebrew.
  #
  #  - CLI tools (former `homebrew.brews`)  -> nixpkgs
  #  - GUI apps  (former `homebrew.casks`)  -> brew-nix (`pkgs.brewCasks.*`),
  #    linked into /Applications/Nix Apps by nix-darwin.
  #  - Mac App Store apps stay on the thin Homebrew remnant (homebrew.nix).
  #
  #  Dropped (not in nixpkgs / not a core cask; reinstall manually if needed):
  #    brews: xcode-build-server, jenv, lporg, assemblyai, clippy, ocr, skip
  #    casks: skip (skiptools tap), httpie (HTTPie Desktop discontinued),
  #           msty, rocket (dead download URL — 404), autodesk-fusion
  #           (installer-only, brew-nix yields an empty derivation).
  #    .pkg casks brew-nix can't unpack (Payload not gzip-cpio) and which need
  #    their real installer/driver anyway — keep the Homebrew copy / install
  #    manually: displaylink (DriverKit sysext), jump-desktop-connect (daemon),
  #    parsec (virtual display driver), sf-symbols (installer).
  #
  ###########################################################################

  # ── CLI tools (Homebrew formulae → nixpkgs) ─────────────────────────────
  environment.systemPackages =
    (with pkgs; [
      act
      asdf-vm # asdf
      autoconf269 # autoconf@2.69
      awscli2 # awscli
      btop
      cloudflared
      cmake
      croc
      direnv
      dive
      docker-compose
      entr
      expat
      fastfetch # neofetch (removed upstream)
      fastlane
      flyctl
      fontforge
      gh
      ghostscript
      git-lfs
      glow
      gum
      helmfile
      httpie
      inetutils # telnet
      jujutsu # jj
      k9s
      kubectx
      kubefwd
      mysql84 # mysql
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
    ])

    # ── GUI apps (Homebrew casks → brew-nix) ──────────────────────────────
    ++ (with pkgs.brewCasks; [
      affinity
      android-platform-tools
      android-studio
      bambu-studio
      barrier
      bentobox
      blender
      chatgpt
      chromedriver
      claude
      crossover
      cryptomator
      discord
      docker-desktop
      fantastical
      figma
      ghostty
      gitbutler
      hidock
      iterm2
      itermai
      jordanbaird-ice
      mac-mouse-fix
      modern-csv
      monodraw
      mountain-duck
      notion
      obsidian
      orion
      postico
      proxyman
      runjs
      slack
      stats
      sublime-merge
      sublime-text
      tomatobar
      typora
      zed
      zoom
    ])

    # casks whose attr name isn't a valid bare identifier (leading digit)
    ++ [
      pkgs.brewCasks."1password"
      pkgs.brewCasks."1password-cli"
    ]

    # casks needing an explicit hash (see pinnedCasks above)
    ++ pinnedCasks;
}
