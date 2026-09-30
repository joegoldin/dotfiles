# Zed built one derivation per crate (crate2nix + buildRustCrate) instead of
# crane's two monolithic derivations, so a failed build keeps every crate that
# finished and a Zed bump reuses every third-party crate whose inputs did not
# change. crate2nix runs at build time through drowse (dynamic derivations),
# so no generated Cargo.nix is committed and evaluation needs no IFD. Building
# requires the dynamic-derivations aspect on the building machine.
#
# Upstream's crane package stays the source of truth for the build
# environment: its commonArgs supply the filtered source, the vendored
# dependencies, the toolchain and the Zed-specific environment.
{
  lib,
  pkgs,
  runCommand,
  writeText,
  symlinkJoin,
  crate2nix,

  drowse,
  zedSource,
  upstreamZedPackage,
  livekit,
}:
let
  inherit (upstreamZedPackage.passthru) craneLib commonArgs;
  inherit (commonArgs) version;
  rustToolchain = craneLib.rustc;

  # Upstream's filtered source leaves out Cargo.lock (crane takes it as a
  # separate argument); crate2nix and cargo-about both need it in the tree.
  sourceWithLock = runCommand "zed-source" { } ''
    cp -r ${commonArgs.src} $out
    chmod -R u+w $out
    cp ${zedSource}/Cargo.lock $out/Cargo.lock
  '';

  # The assets crate embeds assets/licenses.md, so it has to exist before
  # that crate compiles; upstream generates it in the crane build's preBuild.
  licenses = craneLib.mkCargoDerivation (
    removeAttrs commonArgs [ "env" ]
    // {
      pname = "zed-licenses";
      src = sourceWithLock;
      cargoArtifacts = null;
      doInstallCargoArtifacts = false;
      buildPhaseCargoCommand = "ALLOW_MISSING_LICENSES=yes bash script/generate-licenses $out";
      installPhaseCommand = "";
    }
  );

  # Every workspace crate builds from this one tree (see crates.nix), with the
  # files upstream's preBuild writes into it before compiling.
  workspaceSource = runCommand "zed-workspace-source" { } ''
    cp -r ${sourceWithLock} $out
    chmod -R u+w $out
    cp ${licenses} $out/assets/licenses.md
    echo nightly > $out/crates/zed/RELEASE_CHANNEL
  '';

  # crate2nix prefetches git dependencies it has no hash for, which the build
  # sandbox cannot do. builtins.fetchGit already runs at eval time for crane's
  # vendoring, and its narHash is the hash pkgs.fetchgit produces for the same
  # checkout, so the hashes come from there instead of a committed file.
  # crate2nix matches entries by crate name and version.
  crateHashes =
    let
      lockPackages = (lib.importTOML "${zedSource}/Cargo.lock").package;
      gitPackages = lib.filter (p: lib.hasPrefix "git+" (p.source or "")) lockPackages;
      narHash =
        source:
        let
          urlAndRev = lib.splitString "#" (lib.removePrefix "git+" source);
        in
        (builtins.fetchGit {
          url = lib.head (lib.splitString "?" (lib.head urlAndRev));
          rev = lib.elemAt urlAndRev 1;
          allRefs = true;
          submodules = true;
        }).narHash;
    in
    writeText "crate-hashes.json" (
      builtins.toJSON (
        lib.listToAttrs (
          map (p: lib.nameValuePair "${p.name} ${p.version} (${p.source})" (narHash p.source)) gitPackages
        )
      )
    );

  zedCrates = drowse.instantiate (finalAttrs: {
    pname = "zed-editor";
    inherit version;
    src = workspaceSource;

    nativeBuildInputs = [
      crate2nix
      rustToolchain
    ];

    # cargo metadata runs offline against crane's vendored dependencies.
    # crate2nix rewrites crate-hashes.json, so it must not stay read-only.
    preBuild = ''
      install -m644 ${crateHashes} crate-hashes.json
      cat ${commonArgs.cargoVendorDir}/config.toml >> .cargo/config.toml
      crate2nix generate
    '';

    env.NIX_PATH = "nixpkgs=${pkgs.path}";

    expr = ''
      import ${./crates.nix} {
        cargoNix = ./Cargo.nix;
        root = toString ./.;
        name = ${builtins.toJSON finalAttrs.passthru.outName};
        version = ${builtins.toJSON version};
        toolchain = ${builtins.toJSON "${rustToolchain}"};
        workspaceSource = ${builtins.toJSON "${workspaceSource}"};
        livekit = ${builtins.toJSON "${livekit}"};
        fontsConf = ${builtins.toJSON "${commonArgs.env.FONTCONFIG_FILE}"};
        commitSha = ${builtins.toJSON commonArgs.env.ZED_COMMIT_SHA};
        updateExplanation = ${builtins.toJSON commonArgs.env.ZED_UPDATE_EXPLANATION};
      }
    '';
  });
in
# drowse's result is a symlink to the dynamically built output; joining it
# gives home-manager an ordinary directory tree.
symlinkJoin {
  pname = "zed-editor";
  inherit version;
  paths = [ zedCrates ];
  passthru = { inherit zedCrates licenses crateHashes; };
  meta = upstreamZedPackage.meta // {
    platforms = lib.platforms.linux;
  };
}
