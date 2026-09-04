# KiCad PCM addon for Konnect (github.com/mixelpixx/Konnect), built the way
# nixpkgs builds kicadAddons.kikit: the derivation produces the PCM zip at
# $out/${addonPath}, and `kicad.override { addons = [ ... ]; }` unpacks it into
# the wrapper's stock data path.
#
# `addonPath` and `python3` are supplied by kicad.callPackage, and kicad
# re-`override`s both when it takes the addon, so they must stay in the
# signature even where they are unused here.
{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  rustPlatform,
  cmake,
  pkg-config,
  protobuf,
  zip,
  strip-nondeterminism,
  python3,
  addonPath,
}:
let
  version = "0.11.0-unstable-2026-08-27";

  src = fetchFromGitHub {
    owner = "mixelpixx";
    repo = "Konnect";
    # 0.11.0 is only tagged in Cargo.toml; the newest git tag is v0.9.0.
    rev = "dbd2948890eb6781d1df3a8343b2a813b33bbb10";
    hash = "sha256-BGLa51tec5d84wJU8i4Mt9nCIeTAZrk9ZBemGthzlJc=";
  };

  konnect = rustPlatform.buildRustPackage {
    pname = "konnect";
    inherit version src;

    cargoHash = "sha256-4PVbPyw+uYYW5P6UFdWjZlyB48Ul2RT57LeGixH3VJ0=";

    nativeBuildInputs = [
      cmake
      pkg-config
      protobuf
    ];

    PROTOC = "${protobuf}/bin/protoc";
    PROTOC_INCLUDE = "${protobuf}/include";

    cargoBuildFlags = [
      "-p"
      "konnect"
      "--bin"
      "konnect"
    ];

    # Only the MCP server binary is packaged into the addon; the workspace's
    # protocol tests spawn extra crates that are not built here.
    doCheck = false;

    meta.mainProgram = "konnect";
  };

  platform = if stdenv.hostPlatform.isDarwin then "macos" else "linux";
in
stdenvNoCC.mkDerivation {
  pname = "kicadaddon-konnect";
  inherit version src;

  nativeBuildInputs = [
    python3
    zip
    strip-nondeterminism
  ];

  buildPhase = ''
    runHook preBuild

    patchShebangs packaging/build-pcm.sh
    packaging/build-pcm.sh \
      --version ${lib.head (lib.splitString "-" version)} \
      --binary ${lib.getExe konnect} \
      --platform ${platform} \
      --out dist
    strip-nondeterminism --type zip dist/*.zip

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    mv dist/*.zip $out/${addonPath}

    runHook postInstall
  '';

  meta = {
    description = "KiCad addon exposing the board to AI assistants over MCP";
    homepage = "https://github.com/mixelpixx/Konnect";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
