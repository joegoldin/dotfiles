# SunFounder PiCrawler library — the quadruple-leg gait/IK controller. Its
# `Picrawler` class subclasses robot_hat.Robot, so robot-hat is the core dep;
# readchar is pulled in for the interactive example/calibration scripts.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  robot-hat,
  readchar,
}:
buildPythonPackage rec {
  pname = "picrawler";
  version = "2.1.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "sunfounder";
    repo = "picrawler";
    rev = "6f354faee60c7662b0fafca39dbcec1c14097cdb"; # branch main
    hash = "sha256-kWYzcyC8x6Qo3NAyQi7m9h8+0WCpf22SXXaFfa4HTkg=";
  };

  # Pin the version statically (avoid importing picrawler -> robot_hat at build).
  postPatch = ''
    if grep -q 'dynamic = \["version"\]' pyproject.toml; then
      substituteInPlace pyproject.toml \
        --replace-fail 'dynamic = ["version"]' 'version = "${version}"'
      sed -i '/^\[tool\.setuptools\.dynamic\]/,/^version = {attr/d' pyproject.toml
    fi
  '';

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    robot-hat
    readchar
  ];

  # picrawler.__init__ imports robot_hat (Devices()/hardware) — runtime-only.
  pythonImportsCheck = [ ];
  pythonRelaxDeps = true;
  doCheck = false;

  meta = {
    description = "SunFounder PiCrawler quadruped robot library (named gaits + leg inverse kinematics), built on robot_hat";
    homepage = "https://github.com/sunfounder/picrawler";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
