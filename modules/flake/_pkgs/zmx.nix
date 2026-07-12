{
  lib,
  stdenv,
  fetchFromGitHub,
  cacert,
  zig_0_15,
}:
let
  pname = "zmx";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "neurosnap";
    repo = "zmx";
    tag = "v${version}";
    hash = "sha256-OkXtVf/LdBrZL6FH9TGx+mIhUXt2eSugLxZyMd+HL6k=";
  };

  # The Zig package closure (ghostty for libghostty-vt + its transitive
  # deps), pinned by the hashes in build.zig.zon. Fixed-output derivation so
  # `zig fetch` gets network access; the result seeds the package cache of
  # the offline main build. --fetch=all (not =needed) because the build
  # graph lazily requests extra packages, and which ones differs per
  # platform — =all is the same superset everywhere, keeping this single
  # outputHash valid on linux and darwin. Refresh the hash on version bumps.
  zigDeps = stdenv.mkDerivation {
    pname = "${pname}-zig-deps";
    inherit version src;

    nativeBuildInputs = [ zig_0_15 ];

    buildPhase = ''
      runHook preBuild
      export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
      export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
      zig build --fetch=all --color off
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r $ZIG_GLOBAL_CACHE_DIR/p $out
      runHook postInstall
    '';

    # No fixup: patchShebangs would write store paths into the fixed output.
    dontFixup = true;

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-TwKoeaE4g5G7t7smKoqHkCCh998nSqKx5k6sO2vDlGs=";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  # zmx needs exactly zig 0.15 (build.zig.zon minimum_zig_version; 0.16
  # breaks both zmx's and ghostty's build.zig).
  nativeBuildInputs = [ zig_0_15 ];

  # Zig needs a writable global cache directory; seed its package store from
  # the fixed-output deps derivation so the build never touches the network.
  #
  # On darwin, ghostty's build insists on Zig's native SDK detection, which
  # shells out to `xcode-select --print-path` and `xcrun --sdk X
  # --show-sdk-path` — and with default options it configures xcframework
  # steps that probe for the *iphoneos* SDK, which no nixpkgs package can
  # ever answer (the sandbox has no Xcode at all). Shim both tools to echo
  # $SDKROOT (the stdenv apple-sdk): the macos answer is the real SDK the
  # compile steps need, and the iOS answer only has to be non-empty because
  # zmx never builds those steps — it only consumes the ghostty-vt module.
  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR"
    cp -r ${zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
    chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR/p"
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir -p "$TMPDIR/xcode-shims"
    for tool in xcode-select xcrun; do
      printf '#!/bin/sh\necho "$SDKROOT"\n' > "$TMPDIR/xcode-shims/$tool"
      chmod +x "$TMPDIR/xcode-shims/$tool"
    done
    export PATH="$TMPDIR/xcode-shims:$PATH"
  '';

  buildPhase = ''
    runHook preBuild
    zig build -Doptimize=ReleaseSafe --color off
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp zig-out/bin/zmx $out/bin/zmx
    runHook postInstall
  '';

  meta = with lib; {
    description = "Session persistence for terminal processes: attach/detach without the window management";
    homepage = "https://github.com/neurosnap/zmx";
    license = licenses.mit;
    mainProgram = "zmx";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
