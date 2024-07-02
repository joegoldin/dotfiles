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
    version = "0.35.1";
    commit = "a915e3254b1192ce240c078da83fc1768a6e3e90";
    sha256 = "0k89z9j489wgidn3f1r1bq19jh3v0h0m09ghqldprvyckyv4417m";

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
}
