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
    version = "0.48.7";
    commit = "1d623c4cc1d3bb6e0fe4f1d5434b47b958b05870";
    sha256 = "02hfsjh2yy4ahi0igjg91rab16v97ldcnbd973rfzcxd986s896w";

    src = pkgs.fetchurl {
      url = "https://cursor.blob.core.windows.net/remote-releases/${version}-${commit}/vscode-reh-linux-x64.tar.gz";
      sha256 = "02hfsjh2yy4ahi0igjg91rab16v97ldcnbd973rfzcxd986s896w";
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
}
