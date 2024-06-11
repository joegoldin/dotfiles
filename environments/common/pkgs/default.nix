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
    version = "0.35.0";
    commit = "5f9353ed8be369c4ac2b4d43596f5ff281746ec0";
    sha256 = "2e9366fa0bf1c96956c2e06267cea7072266f43318f9c7c697dc0ca075b34580";

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
}
