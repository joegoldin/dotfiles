# SunFounder Robot HAT library (v2.0 branch, the self-contained generation used
# by the robot-hat-v4 docs). The upstream pyproject declares NO dependencies and
# defers real installation to install.py (apt/raspi-config/pip side-effects); we
# drop install.py + the setup.py shim and declare the deps here instead. The
# runtime CLI tools robot_hat shells out to (sox/aplay/amixer/espeak/pico2wave/
# raspi-gpio) are provided on the system PATH by the crawler host, not bundled.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  smbus2,
  gpiozero,
  pyaudio,
  spidev,
  pyserial,
  pillow,
  pygame,
}:
buildPythonPackage rec {
  pname = "robot-hat";
  version = "2.3.6";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "sunfounder";
    repo = "robot-hat";
    rev = "f06fbc6e9ea2da59b428755717fd423dde648eb1"; # branch v2.0
    hash = "sha256-GRTVC6buv/IWB1cQCyxdpDQc2M9h8DrKQCQqPAM+CGI=";
  };

  # setup.py is a deprecated shim that, on `install`, runs install.py (apt,
  # raspi-config, pip, /boot overlay copies). Remove both and pin the version
  # statically so the build never imports robot_hat (its __init__ touches
  # /proc/device-tree + pyaudio, which aren't available in the build sandbox).
  postPatch = ''
    rm -f setup.py install.py
    substituteInPlace pyproject.toml \
      --replace-fail 'dynamic = ["version"]' 'version = "${version}"'
    sed -i '/^\[tool\.setuptools\.dynamic\]/,/^version = {attr/d' pyproject.toml
  '';

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    smbus2
    gpiozero
    pyaudio
    spidev
    pyserial
    pillow
    pygame
  ];

  # Importing robot_hat instantiates Devices() (reads /proc/device-tree) and
  # imports pyaudio/pygame — validate on the Pi at runtime, not in the sandbox.
  pythonImportsCheck = [ ];
  doCheck = false;

  meta = {
    description = "SunFounder Robot HAT library: servos, PWM, ADC, I2C, motors, ultrasonic, music/TTS for Raspberry Pi";
    homepage = "https://github.com/sunfounder/robot-hat";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
