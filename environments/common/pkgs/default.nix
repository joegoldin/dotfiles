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
    version = "0.49.6";
    commit = "0781e811de386a0c5bcb07ceb259df8ff8246a50";
    sha256 = "1yghjc794a10w5hwwn27i6gdlnl6wpsg859pncrxpwq3irxjaxz9";

    src = pkgs.fetchurl {
      url = "https://cursor.blob.core.windows.net/remote-releases/${version}-${commit}/vscode-reh-linux-x64.tar.gz";
      sha256 = "1yghjc794a10w5hwwn27i6gdlnl6wpsg859pncrxpwq3irxjaxz9";
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
    
  #   src = pkgs.fetchFromGitHub {
  #     owner = "sedwards2009";
  #     repo = "extraterm";
  #     rev = "v${version}";
  #     sha256 = "sha256-H5aP7inGaUXD1SUyijsaaR5qki6yIzaq71MYPaoNSxo=";
  #   };
    
  #   nativeBuildInputs = [ pkgs.yarn pkgs.nodejs ];
    
  #   buildInputs = [ pkgs.yarn pkgs.nodejs ];
    
  #   buildPhase = ''
  #     export HOME=$PWD
  #     ${pkgs.yarn}/bin/yarn install
  #     ${pkgs.yarn}/bin/yarn run build
  #   '';
    
  #   installPhase = ''
  #     mkdir -p $out/bin $out/share/applications $out/lib
      
  #     cp -r dist $out/lib/
  #     cp extraterm $out/bin/
  #     cp extraterm.desktop $out/share/applications/
  #     sed -i 's|Exec=.*|Exec=$out/bin/extraterm|' $out/share/applications/extraterm.desktop
      
  #     chmod +x $out/bin/extraterm
  #   '';
  # };
}
