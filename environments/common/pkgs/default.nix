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
    version = "0.39.0";
    commit = "67685f6d849a40497339e3f7bc51bcc54208f410";
    sha256 = "0i367ns2f138fnns3f98g4vs01ijnlk70wda73ya8dj1r8c0fvwh";

    src = pkgs.fetchurl {
      url = "https://cursor.blob.core.windows.net/remote-releases/${version}-${commit}/vscode-reh-linux-x64.tar.gz";
      sha256 = "${sha256}";
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
    sha256 = "sha256-tdn4z0tIc0nC5nApGwT7GYbiY91OTA4hNXZDDQ6g9qU=";

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
