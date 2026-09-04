# The `tsci` CLI from tscircuit, which renders React-style circuit source into
# schematics, PCBs and fabrication output.
#
# npm publishes the CLI without a lockfile, so the pinned tree lives beside this
# file: package.json names the version and package-lock.json fixes every
# transitive dependency. Regenerate both with
#   npm install --package-lock-only --ignore-scripts
# after changing the version, then update npmDepsHash.
{
  lib,
  buildNpmPackage,
  makeWrapper,
  bun,
  stdenv,
  autoPatchelfHook,
}:
buildNpmPackage (finalAttrs: {
  pname = "tscircuit";
  version = "0.0.2463";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };

  # The v1 fetcher misses packages this tree reaches only through peer
  # dependencies, and npm ci then fails ENOTCACHED on them.
  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-Q523rjcO8/xu1QF5in8qTdX+2UB9cdeHRV798+1QfMY=";

  # Peer ranges in this tree resolve to versions that are not in the lock, and
  # npm ci then tries to reach the registry for them. The lock beside this file
  # is generated with the same flag.
  npmFlags = [ "--legacy-peer-deps" ];

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  # Nothing to compile: this package exists to pin the dependency tree.
  dontNpmBuild = true;

  # resvg-js ships a prebuilt .node per platform, which autoPatchelfHook fixes
  # up in place.
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/tscircuit
    cp -r node_modules package.json $out/lib/tscircuit/

    # The CLI is written for bun -- it imports .tsx sources directly, which
    # node refuses with ERR_UNKNOWN_FILE_EXTENSION -- and upstream's shebang
    # says so. npm is still what pins the dependency tree above.
    makeWrapper ${lib.getExe bun} $out/bin/tsci \
      --add-flags run \
      --add-flags $out/lib/tscircuit/node_modules/tscircuit/cli.mjs
    ln -s $out/bin/tsci $out/bin/tscircuit

    runHook postInstall
  '';

  meta = {
    description = "CLI for tscircuit, electronics design in React";
    homepage = "https://github.com/tscircuit/tscircuit";
    license = lib.licenses.mit;
    mainProgram = "tsci";
    platforms = lib.platforms.unix;
  };
})
