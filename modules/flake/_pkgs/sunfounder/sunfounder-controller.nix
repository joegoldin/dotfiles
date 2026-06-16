# SunFounder Controller server module — pairs with the SunFounder Controller
# mobile app over WebSocket to drive the robot and toggle vision features.
# setup.py-only (no pyproject); its sole declared dep is websockets.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  websockets,
}:
buildPythonPackage {
  pname = "sunfounder-controller";
  version = "0.0.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "sunfounder";
    repo = "sunfounder-controller";
    rev = "eb93503ce9406ea3d240606ad1c3aeabc025b5c6"; # branch master
    hash = "sha256-H1QUcc+k1ekmDWqVmxO0C8B6AW8KL/c19+yslq5egkI=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [ websockets ];

  pythonImportsCheck = [ "sunfounder_controller" ];
  doCheck = false;

  meta = {
    description = "SunFounder Controller server: WebSocket bridge to the SunFounder Controller mobile app";
    homepage = "https://github.com/sunfounder/sunfounder-controller";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
