# One source-built payload for the PCM addon and the command-line tools.
# Keep the canonical Rust module in place at build time: upstream's PCM
# loader otherwise tries to copy a platform binary into the read-only store.
{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  rustPlatform,
  python3,
  zip,
  strip-nondeterminism,
  addonPath,
}:
let
  version = "0.22.0";

  src = fetchFromGitHub {
    owner = "drandyhaas";
    repo = "KiCadRoutingTools";
    tag = "v${version}";
    hash = "sha256-ANubFsuIc4Wd3SZhxZVK0ASohxlKrfObKTk1TBThdNE=";
  };

  router = rustPlatform.buildRustPackage {
    pname = "kicad-grid-router";
    inherit version src;
    sourceRoot = "source/rust_router";
    cargoHash = "sha256-Bi7xSMHnBLqdtDC77LpTG4DjBbZW/P2W10PFgOFVTKc=";

    nativeBuildInputs = [ python3 ];
    PYO3_PYTHON = python3.interpreter;
    # PyO3 0.23 predates KiCad's Python 3.14; this crate targets the stable
    # Python 3.9+ ABI rather than a particular interpreter's private API.
    PYO3_USE_ABI3_FORWARD_COMPATIBILITY = "1";

    # There are no Rust unit tests. Exercise the extension through Python
    # after installation, and the GUI/CLI through the wrapped KiCad runtime.
    doCheck = false;
    doInstallCheck = true;
    nativeInstallCheckInputs = [ (python3.withPackages (ps: [ ps.numpy ])) ];
    installCheckPhase = ''
      runHook preInstallCheck
      PYTHONPATH="$out/lib" python3 -c 'import grid_router; assert grid_router.__version__ == "${version}"'
      runHook postInstallCheck
    '';

    postInstall = ''
      ln -s libgrid_router${stdenv.hostPlatform.extensions.sharedLibrary} $out/lib/grid_router.so
    '';
  };
in
stdenvNoCC.mkDerivation {
  pname = "kicadaddon-routing-tools";
  inherit version src;

  nativeBuildInputs = [
    python3
    zip
    strip-nondeterminism
  ];

  # KiCad's wrapper follows the addon's propagated inputs when constructing
  # PYTHONPATH. Supplying these here also feeds the existing kicad-python.
  propagatedBuildInputs = with python3.pkgs; [
    numpy
    scipy
    shapely
  ];

  buildPhase = ''
    runHook preBuild

    export PYTHONDONTWRITEBYTECODE=1
    python3 - "$TMPDIR/pcm" <<'PY'
    import sys
    from pathlib import Path
    from package_pcm import stage_plugins, write_top_level, read_version

    stage = Path(sys.argv[1])
    stage_plugins(stage)
    write_top_level(stage, read_version())
    PY
    cp ${router}/lib/grid_router.so "$TMPDIR/pcm/plugins/rust_router/grid_router.so"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r "$TMPDIR/pcm/plugins" $out/share/kicad-routing-tools
    (cd "$TMPDIR/pcm" && zip -rqX $out/${addonPath} .)
    strip-nondeterminism --type zip $out/${addonPath}

    runHook postInstall
  '';

  passthru = {
    inherit router;
    cliScripts = {
      route = "py_router/route.py";
      route-diff = "py_router/route_diff.py";
      route-planes = "py_router/route_planes.py";
      repair-planes = "py_router/repair_planes.py";
      bga-fanout = "py_router/bga_fanout.py";
      qfn-fanout = "py_router/qfn_fanout.py";
      place-optimize = "py_placer/place_optimize.py";
      place-fanout-clearance = "py_placer/place_fanout_clearance.py";
      check-drc = "py_router/check_drc.py";
      check-connected = "py_router/check_connected.py";
      make-plan = "py_router/make_plan.py";
      run-plan = "py_router/run_plan.py";
    };
  };

  meta = {
    description = "Rust-accelerated KiCad autorouter, routing tools and PCB editor plugin";
    homepage = "https://github.com/drandyhaas/KiCadRoutingTools";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
