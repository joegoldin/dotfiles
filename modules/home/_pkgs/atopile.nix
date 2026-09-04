# atopile 0.15.8: the `ato` compiler, which turns .ato source into KiCad
# schematics and boards.
#
# nixpkgs carries 0.12.5, three minor versions back, and the gap is not a
# simple bump: 0.15's core (faebryk) is written in Zig and built through
# scikit-build-core rather than the cmake/nanobind path nixpkgs packages, and
# it pulls two dependencies nixpkgs does not have. So this builds the PyPI
# sdist from scratch rather than overriding the nixpkgs derivation.
{
  lib,
  python3Packages,
  fetchPypi,
  fetchurl,
  runCommand,
  cmake,
  ninja,
  zig,
}:
let
  # Upstream builds with the `ziglang` PyPI package, which is nothing but the
  # zig binaries plus a module that execs them. nixpkgs has the compiler at
  # exactly the pinned 0.16.0, so stand up the module around it instead of
  # vendoring a second toolchain.
  ziglang = python3Packages.buildPythonPackage {
    pname = "ziglang";
    inherit (zig) version;
    pyproject = true;

    # The real package is the zig binaries plus a module that execs them, and
    # the build reads its version from the pin, so it has to be a proper
    # distribution rather than files dropped in site-packages.
    src = runCommand "ziglang-src-${zig.version}" { } (''
      mkdir -p $out/ziglang
      touch $out/ziglang/__init__.py

      cat > $out/pyproject.toml <<'EOF'
      [build-system]
      requires = ["setuptools"]
      build-backend = "setuptools.build_meta"

      [project]
      name = "ziglang"
      version = "@version@"

      [tool.setuptools]
      packages = ["ziglang"]
      EOF

      cat > $out/ziglang/__main__.py <<'EOF'
      import os
      import sys

      os.execv("@zig@", ["zig", *sys.argv[1:]])
      EOF

      substituteInPlace $out/pyproject.toml --replace-fail "@version@" "${zig.version}"
      substituteInPlace $out/ziglang/__main__.py --replace-fail "@zig@" "${zig}/bin/zig"
    '');

    build-system = [ python3Packages.setuptools ];

    pythonImportsCheck = [ "ziglang" ];
  };

  pyaaf2 = python3Packages.buildPythonPackage rec {
    pname = "pyaaf2";
    version = "1.7.1";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-4Y5ahLyk6hjBueg4SVji9tKWGVyQGkSPcfgwsiuJwiU=";
    };

    build-system = [ python3Packages.setuptools ];

    pythonImportsCheck = [ "aaf2" ];

    meta = {
      description = "Python module for reading and writing Advanced Authoring Format files";
      homepage = "https://github.com/markreidvfx/pyaaf2";
      license = lib.licenses.mit;
    };
  };

  # nixpkgs sits on 0.9.7 and 0.15.8 wants 0.9.9, which also grew a dependency.
  atopile-easyeda2kicad = python3Packages.atopile-easyeda2kicad.overridePythonAttrs (old: rec {
    version = "0.9.9";

    src = fetchPypi {
      pname = "atopile_easyeda2kicad";
      inherit version;
      hash = "sha256-V68i6B8223VxgVYjVWtLisQkr+UFjB4HwgrKP5DeF0Q=";
    };

    dependencies = old.dependencies ++ [ python3Packages.fake-useragent ];
  });

  # atopile's fork of KiCad's own python bindings, published wheel-only.
  atopile-kicad-python = python3Packages.buildPythonPackage {
    pname = "atopile-kicad-python";
    version = "0.5.1";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/d7/97/6f27d3d7d49c9064009526f4b15b24b890bae3d8045f3b8c5dff7e96ff71/atopile_kicad_python-0.5.1-py3-none-any.whl";
      hash = "sha256-rVtr6rW8LkB0Y2lc8xJwoGRn2D3vP5n+N3VvXBB/SSo=";
    };

    dependencies = with python3Packages; [
      protobuf5
      pynng
    ];

    pythonImportsCheck = [ "kipy" ];

    meta = {
      description = "KiCad IPC API bindings, as forked for atopile";
      homepage = "https://pypi.org/project/atopile-kicad-python/";
      license = lib.licenses.gpl3Only;
    };
  };
in
python3Packages.buildPythonApplication rec {
  pname = "atopile";
  version = "0.15.8";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-dsQvM/FRlH2+Uz1NCgS2BiO4TDjO1uQNF8MJnl9ZuVU=";
  };

  # The fork exists only to keep editable installs working (see upstream's own
  # comment above the requirement); a store build never installs editable.
  postPatch = ''
    # atopile still points its config, plugin and footprint paths at KiCad 9;
    # upstream marks the constant "@kicad10" as the thing to change. It is used
    # for path construction only, so aim it at the KiCad this profile ships or
    # `ato` cannot read kicad_common.json to turn the IPC API on.
    substituteInPlace src/faebryk/libs/kicad/paths.py \
      --replace-fail 'KICAD_VERSION = "9.0"' 'KICAD_VERSION = "10.0"'

    substituteInPlace pyproject.toml \
      --replace-fail \
        '"scikit-build-core @ git+https://github.com/atopile/scikit-build-core.git@feature/allow_editable",' \
        '"scikit-build-core",'
  '';

  build-system = with python3Packages; [
    hatchling
    hatch-vcs
    nanobind
    scikit-build-core
    ziglang
  ];

  nativeBuildInputs = [
    cmake
    ninja
  ];

  # scikit-build-core drives cmake itself.
  dontUseCmakeConfigure = true;

  # zig writes its build cache under HOME, which the sandbox does not give us.
  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
  '';

  pythonRelaxDeps = [
    # nixpkgs runs ahead of the pins: a patch past prompt-toolkit's ==, a minor
    # past ruff's ceiling, and a minor past deprecated's ~= -- nixpkgs relaxes
    # the last one for 0.12.5 too.
    "deprecated"
    "prompt-toolkit"
    "ruff"
  ];

  dependencies =
    with python3Packages;
    [
      anthropic
      antlr4-python3-runtime
      black
      case-converter
      cookiecutter
      dataclasses-json
      deprecated
      fastapi
      fastapi-github-oidc
      freetype-py
      gitpython
      httpx
      jinja2
      keyring
      kicadcliwrapper
      matplotlib
      mcp
      more-itertools
      nanobind
      natsort
      numpy
      openai
      ordered-set
      pathvalidate
      platformdirs
      prompt-toolkit
      psutil
      pydantic-settings
      pygls
      pytest
      pyyaml
      questionary
      rich
      ruamel-yaml
      ruff
      semver
      sexpdata
      shapely
      truststore
      typer
      typing-extensions
      urllib3
      uvicorn
      watchdog
      websockets
      zstd
    ]
    ++ [
      atopile-easyeda2kicad
      atopile-kicad-python
      pyaaf2
    ];

  # Upstream's suite wants a git checkout, downloads parts from JLCPCB, and
  # runs KiCad; nixpkgs disables most of it even at 0.12.5.
  doCheck = false;

  pythonImportsCheck = [ "atopile" ];

  meta = {
    description = "Compiler for .ato, a language for describing circuit boards";
    homepage = "https://github.com/atopile/atopile";
    license = lib.licenses.mit;
    mainProgram = "ato";
  };
}
