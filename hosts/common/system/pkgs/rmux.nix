{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rmux";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "Helvesec";
    repo = "rmux";
    tag = "v${version}";
    hash = "sha256-PP1xfTQ/hlKqzhPUhuGwcLgXUG/AO48JRKoaSw2yhiE=";
  };

  cargoHash = "sha256-T5KLTolNRLRNUdZOm17JFDoXRMs+khLmWvVF98egw60=";

  # The integration suite drives real PTYs and attach/choose-tree timing,
  # which is not reproducible inside the hermetic Nix build sandbox.
  doCheck = false;

  meta = {
    description = "Universal Rust multiplexer with a typed SDK — drive any CLI or TUI app from code";
    homepage = "https://github.com/Helvesec/rmux";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "rmux";
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };
}
