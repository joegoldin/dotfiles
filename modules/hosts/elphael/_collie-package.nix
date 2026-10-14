# Collie built from source. Upstream's flake package wraps the prebuilt
# release binary instead; building here keeps what runs identical to the
# reviewed source. Same tree layout as the release
# tarball: bridge/root.ts resolves the install root through the bin/collie
# symlink and accepts it only where herdr-plugin.toml sits.
{
  lib,
  stdenv,
  src,
  bun,
}:
let
  version = (lib.importJSON "${src}/package.json").version;

  # Fixed-output: bun install needs the network. --frozen-lockfile installs
  # exactly the lockfiles' pins, and neither package.json has lifecycle
  # scripts to skip.
  deps = stdenv.mkDerivation {
    pname = "collie-deps";
    inherit version src;
    nativeBuildInputs = [ bun ];
    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache
      bun install --frozen-lockfile --ignore-scripts --no-progress
      (cd web && bun install --frozen-lockfile --ignore-scripts --no-progress)
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/web
      cp -R node_modules $out/node_modules
      cp -R web/node_modules $out/web/node_modules
      runHook postInstall
    '';
    # A store reference would be illegal in a fixed-output path.
    dontFixup = true;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-SzLGASA8ZJvqXbN0XwSxE7hNAulOwS003CofOkMqDN0=";
  };
in
stdenv.mkDerivation {
  pname = "collie";
  inherit version src;
  nativeBuildInputs = [ bun ];
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    cp -R ${deps}/node_modules node_modules
    cp -R ${deps}/web/node_modules web/node_modules
    chmod -R u+w node_modules web/node_modules
    # Run vite on bun directly: its bin's /usr/bin/env node shebang has no
    # interpreter in the sandbox.
    (cd web && bun --bun node_modules/vite/bin/vite.js build)
    bun build --compile cli/main.ts --outfile collie
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    root=$out/lib/collie
    mkdir -p $root/bin $root/web $root/scripts $out/bin
    install -m 0755 collie $root/bin/collie
    cp -R web/dist $root/web/dist
    cp herdr-plugin.toml package.json .env.example CHANGELOG.md LICENSE README.md $root/
    cp -R docs $root/docs
    install -m 0755 scripts/collie-ctl.sh $root/scripts/collie-ctl.sh
    ln -s $root/bin/collie $out/bin/collie
    runHook postInstall
  '';

  # The compiled binary carries its bundle appended to the ELF image;
  # stripping or patching it leaves a binary that no longer starts.
  dontStrip = true;
  dontPatchELF = true;

  meta = {
    description = "Phone web UI for the AI agents running in your terminal";
    homepage = "https://github.com/AltanS/collie";
    license = lib.licenses.mit;
    mainProgram = "collie";
    platforms = lib.platforms.linux;
  };
}
