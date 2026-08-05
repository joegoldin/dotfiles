{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  udev,
}:
rustPlatform.buildRustPackage rec {
  pname = "litra-autotoggle";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "timrogers";
    repo = "litra-autotoggle";
    tag = "v${version}";
    hash = "sha256-fx3j3LIdiSqnsNb66BRzz/q1qlLbPsfrtfKFKesJw0k=";
  };

  cargoHash = "sha256-jCLUdPUGdhFTysKLCqE1JGfUVzzDdvQDFPnelyQcDSY=";

  # Upstream's Linux `--video-device` filter is a no-op: it points inotify at
  # the device node itself, and inotify only reports a file name for events on
  # entries *inside* a watched directory, so every event is dropped by the
  # name filter and the light never toggles (verified on elphael against
  # v1.4.0). Watch the device's parent directory and filter on its resolved
  # file name instead, which also makes persistent /dev/v4l/by-id/... paths
  # work. Drop this once upstream carries the fix.
  patches = [ ./litra-autotoggle-watch-parent-dir.patch ];

  # On Linux the hidapi crate (via the litra crate) builds its vendored C
  # library against libudev (linux-static-hidraw, its default backend);
  # darwin goes through IOKit and needs neither.
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ pkg-config ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ udev ];

  meta = {
    description = "Turn a Logitech Litra light on when your webcam turns on, and off when it turns off";
    homepage = "https://github.com/timrogers/litra-autotoggle";
    license = lib.licenses.mit;
    mainProgram = "litra-autotoggle";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
