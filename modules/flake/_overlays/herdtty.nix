{ inputs }:
_final: prev:
let
  inherit (prev.stdenv.hostPlatform) system isLinux;
  packages = inputs.herdtty.packages.${system};
in
{
  # Herdtty follows our herdr input; use its tested direct-terminal patch for
  # the service as well as the GUI, without changing upstream's toolchain pins.
  inherit (packages) herdr;
  herdtty =
    if isLinux then
      packages.default
    else
      prev.callPackage ./_herdtty/local.nix {
        source = inputs.herdtty;
        signingIdentity = (import "${inputs.dotfiles-secrets}/apple-signing.nix").developmentIdentity;
      };
  herdtty-release =
    if isLinux then
      packages.default
    else
      prev.stdenvNoCC.mkDerivation {
        pname = "herdtty";
        version = "0.3.1";
        src = prev.fetchurl {
          url = "https://github.com/joegoldin/herdtty/releases/download/v0.3.1/herdtty-macos-universal.zip";
          hash = "sha256-0fwk3Z+6fnj1gHqvPit39bAuZThEmyyi37QVnrf8PqY=";
        };
        terminalSrc = prev.fetchurl {
          url = "https://github.com/joegoldin/herdtty/releases/download/v0.3.1/herdtty-terminal-macos-universal.zip";
          hash = "sha256-dAME8ewIRuU6pZBNDgwB9SMQfjIkG+Pg9dF8VZNxQ6I=";
        };
        nativeBuildInputs = [
          prev.unzip
          prev.makeWrapper
        ];
        unpackPhase = ''
          runHook preUnpack
          unzip -q "$src"
          unzip -q "$terminalSrc"
          runHook postUnpack
        '';
        dontConfigure = true;
        dontBuild = true;
        # Preserve Developer ID signatures and stapled notarization tickets.
        dontFixup = true;
        installPhase = ''
          runHook preInstall
          mkdir -p "$out/Applications" "$out/bin"
          cp -R herdtty.app "herdtty Terminal.app" "$out/Applications/"
          makeWrapper "$out/Applications/herdtty.app/Contents/MacOS/herdtty" "$out/bin/herdtty"
          makeWrapper "$out/Applications/herdtty Terminal.app/Contents/MacOS/herdtty" "$out/bin/herdtty-terminal"
          runHook postInstall
        '';
        meta = {
          description = "Ghostty frontend for persistent herdr terminals";
          homepage = "https://github.com/joegoldin/herdtty";
          license = prev.lib.licenses.mit;
          platforms = prev.lib.platforms.darwin;
          mainProgram = "herdtty";
        };
      };
}
