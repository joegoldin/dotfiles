# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
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
      helm-unittest
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
          helm-unittest
        ];
      })
      pluginsDir
      ;
  };

  claude-desktop = pkgs.callPackage ./claude-desktop {};

  lotion = pkgs.callPackage ./lotion {
    electron = pkgs.electron_37;
  };

  happy-cli = pkgs.callPackage ./happy-cli {};
}
