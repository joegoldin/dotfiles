{
  lib,
  python3Packages,
  fetchFromGitHub,
  cmake,
  ninja,
  autoPatchelfHook,
  stdenv,
}:
python3Packages.buildPythonPackage rec {
  pname = "pywhispercpp";
  version = "1.4.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "absadiki";
    repo = "pywhispercpp";
    tag = "v${version}";
    hash = "sha256-8PhI6YDpJQ4F2M96ehG95C/SJ7ZbmyZ0KprgjWjQEzQ=";
    fetchSubmodules = true;
  };

  # Remove repairwheel from build deps (only needed for wheel repair on non-Nix)
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail '"repairwheel",' "" \
      --replace-fail '"ninja",' "" \
      --replace-fail '"cmake>=3.12",' ""
  '';

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
    wheel
  ];

  nativeBuildInputs = [
    cmake
    ninja
    autoPatchelfHook
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  dontUseCmakeConfigure = true;

  # Strip /build/ references from RPATHs before fixupPhase checks for them
  preFixup = ''
    local site="$out/lib/python3.13/site-packages"
    for f in "$site"/libggml*.so "$site"/libwhisper*.so* "$site"/_pywhispercpp*.so; do
      [ -f "$f" ] || continue
      local rpath
      rpath="$(patchelf --print-rpath "$f" 2>/dev/null)" || continue
      local new_rpath
      new_rpath="$(echo "$rpath" | tr ':' '\n' | grep -v '/build/' | paste -sd ':')"
      [ -z "$new_rpath" ] && new_rpath="$site"
      patchelf --set-rpath "$new_rpath" "$f"
    done
  '';

  dependencies = with python3Packages; [
    numpy
    requests
    tqdm
    platformdirs
  ];

  env = {
    SETUPTOOLS_SCM_PRETEND_VERSION = version;
    NO_REPAIR = "1";
  };

  pythonImportsCheck = [ "pywhispercpp" ];

  meta = {
    description = "Python bindings for whisper.cpp";
    homepage = "https://github.com/absadiki/pywhispercpp";
    license = lib.licenses.mit;
  };
}
