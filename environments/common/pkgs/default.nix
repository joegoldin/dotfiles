# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  clai-go = pkgs.buildGoModule rec {
    pname = "clai";
    version = "1.3.16";
    src = pkgs.fetchFromGitHub {
      owner = "baalimago";
      repo = "clai";
      rev = "v${version}";
      sha256 = "sha256-8FHeNQha9cQUQRPYAz40U0MCRjaHB2WwQ9SDiZTuDUU=";
    };
    vendorHash = "sha256-sudsPObEyUJklAAc3ZX7TM3KRkTE0sZRM8EctpmUb+E=";
  };

  cursor-server-linux = pkgs.stdenv.mkDerivation rec {
    pname = "cursor-server-linux";
    version = "0.50.5";
    commit = "96e5b01ca25f8fbd4c4c10bc69b15f6228c80770";
    sha256 = "1i8smj4qdvhcl67k93yc0xxcb1jl1kv3v09g3frmi9n50ay7q932";

    src = pkgs.fetchurl {
      url = "https://cursor.blob.core.windows.net/remote-releases/${version}-${commit}/vscode-reh-linux-x64.tar.gz";
      sha256 = "1i8smj4qdvhcl67k93yc0xxcb1jl1kv3v09g3frmi9n50ay7q932";
    };

    installPhase = ''
      outDir=$out/cursor-server-linux/${sha256}
      mkdir -p $outDir
      tar -xzvf $src -C $outDir
    '';
  };

  google-chrome-stable = pkgs.writeShellScriptBin "google-chrome" ''
    exec -a $0 ${pkgs.google-chrome}/bin/google-chrome-stable $@
  '';

  aws-cli = pkgs.writeShellScriptBin "aws" ''
    unset PYTHONPATH
    exec ${pkgs.awscli2}/bin/aws "$@"
  '';

  shopt-script = pkgs.writeShellScriptBin "shopt" ''
    args="";
    for item in "$@"; do
      args="$args $item";
    done
    shopt $args;
  '';

  iterm2-terminal-integration = pkgs.stdenv.mkDerivation rec {
    pname = "iterm2-terminal-integration";
    version = "0.0.1";
    sha256 = "sha256-aKTt7HRMlB7htADkeMavWuPJOQq1EHf27dEIjKgQgo0=";

    src = pkgs.fetchurl {
      url = "https://iterm2.com/shell_integration/fish";
      sha256 = "${sha256}";
    };

    unpackPhase = ''
      for srcFile in $src; do
        cp $srcFile $(stripHash $srcFile)
      done
    '';

    installPhase = ''
      outDir=$out/bin
      mkdir -p $outDir
      cp $src $outDir/iterm2_shell_integration.fish
    '';
  };

  helm-with-plugins = pkgs.wrapHelm pkgs.kubernetes-helm {
    plugins = with pkgs.kubernetes-helmPlugins; [
      helm-secrets
      helm-diff
      helm-s3
      helm-git
    ];
  };
  helmfile-with-plugins = pkgs.helmfile-wrapped.override {
    inherit
      (pkgs.wrapHelm pkgs.kubernetes-helm {
        plugins = with pkgs.kubernetes-helmPlugins; [
          helm-secrets
          helm-diff
          helm-s3
          helm-git
        ];
      })
      pluginsDir
      ;
  };

  # extraterm = pkgs.stdenv.mkDerivation rec {
  #   pname = "extraterm";
  #   version = "0.81.0";

  #   src = pkgs.fetchzip {
  #     url = "https://github.com/sedwards2009/extraterm/releases/download/v${version}/extratermqt-${version}-linux-x64.zip";
  #     hash = "sha256-wJLl78Fuos0qaLpSr6rbFJJ4kFbuXXkrrIiUCiH4wNY=";
  #     stripRoot = false;
  #   };

  #   nativeBuildInputs = with pkgs; [
  #     makeWrapper
  #   ];

  #   installPhase = ''
  #     runHook preInstall

  #     export SRC_DIR=$src/extratermqt-${version}-linux-x64

  #     mkdir -p $out/bin
  #     mkdir -p $out/opt/extraterm
  #     mkdir -p $out/share/{applications,pixmaps}

  #     cp -r $SRC_DIR/* $out/opt/extraterm/

  #     # Create wrapper script
  #     makeWrapper $out/opt/extraterm/extratermqt $out/bin/extraterm \
  #       --set PATH ${pkgs.lib.makeBinPath (with pkgs; [xdg-utils])}

  #     # Install desktop file
  #     cp $SRC_DIR/extratermqt.desktop $out/share/applications/extraterm.desktop
  #     # Fix desktop file paths
  #     substituteInPlace $out/share/applications/extraterm.desktop \
  #       --replace "Exec=/opt/extratermqt/extratermqt" "Exec=$out/opt/extraterm/extratermqt"

  #     # Extract icon
  #     # install -Dm644 $SRC_DIR/extensions/theme-default/theme/terminal/extraterm_small.png $out/share/pixmaps/extraterm.png

  #     runHook postInstall
  #   '';

  #   meta = with pkgs.lib; {
  #     description = "The swiss army chainsaw of terminal emulators";
  #     homepage = "https://extraterm.org";
  #     license = licenses.mit;
  #     platforms = platforms.linux;
  #     maintainers = [];
  #   };
  # };
}
