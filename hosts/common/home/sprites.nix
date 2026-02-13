{
  pkgs,
  lib,
  ...
}: let
  version = "0.0.1-rc29";

  # Platform-specific sources
  sources = {
    x86_64-linux = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-linux-amd64.tar.gz";
      hash = "sha256-4AVjv/ZWM4QYmOJFz9/ky1w3cO9Vc93Tq0Voa2dRfP4=";
    };
    aarch64-linux = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-linux-arm64.tar.gz";
      hash = "sha256-PECd9HjRFNLMfVBEvNZhyU1JsRdwOY2hmaOdyq4Qd9Y=";
    };
    x86_64-darwin = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-darwin-amd64.tar.gz";
      hash = "sha256-dJLI0Cnv7wyE61/sh6/PnlxzfngYYhTsQI56TgBmE6U=";
    };
    aarch64-darwin = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-darwin-arm64.tar.gz";
      hash = "sha256-HyEHGQF0S9BaKp80jZ8NzcwgtUFGrmycs5cJbCJJTs8=";
    };
  };

  source = sources.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}");
in {
  packages = {
    sprite = pkgs.stdenv.mkDerivation {
      pname = "sprite";
      inherit version;

      src = pkgs.fetchurl {
        inherit (source) url hash;
      };

      sourceRoot = ".";

      nativeBuildInputs = [pkgs.gnutar];

      unpackPhase = ''
        tar -xzf $src
      '';

      installPhase = ''
        mkdir -p $out/bin
        install -m 0755 sprite $out/bin/sprite
      '';

      meta = with lib; {
        description = "Sprite CLI - create and manage Sprites";
        homepage = "https://sprites.dev";
        license = licenses.unfree;
        platforms = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
        mainProgram = "sprite";
      };
    };
  };
}
