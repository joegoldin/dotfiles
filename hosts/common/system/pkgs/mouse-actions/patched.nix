# mouse-actions built from joegoldin/mouse-actions @ configurable-input-rules.
# That fork adds two upstreamable Config fields — `modifier_remaps` and
# `chord_bindings` — used to express drag-shift and the forward+back chord
# entirely in the JSON config instead of as out-of-process daemons.
{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  libx11,
  libxi,
  libxtst,
  libevdev,
  udevCheckHook,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "mouse-actions-fork";
  version = "0.4.5-configurable";

  src = fetchFromGitHub {
    owner = "joegoldin";
    repo = "mouse-actions";
    rev = "02f4faf";
    hash = "sha256-wB2219nL3A+ngsVFcYrzJ1vXojfF8Y6SoUZW/VqO3vs=";
  };

  cargoHash = "sha256-bClutTRxGMQg2r5p9RXAh27lqbPMB8cKHNElvZ5u1K4=";

  doInstallCheck = true;

  buildInputs = [
    libx11
    libxi
    libxtst
    libevdev
  ];

  nativeBuildInputs = [
    pkg-config
    udevCheckHook
  ];

  postInstall = ''
    mkdir -p $out/etc/udev/rules.d/
    echo 'KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"' >> $out/etc/udev/rules.d/80-mouse-actions.rules
    echo 'KERNEL=="/dev/input/event*", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"' >> $out/etc/udev/rules.d/80-mouse-actions.rules
  '';

  meta = {
    description = "mouse-actions with configurable modifier-remaps and chord-bindings (fork)";
    homepage = "https://github.com/joegoldin/mouse-actions";
    license = lib.licenses.mit;
    mainProgram = "mouse-actions";
    platforms = lib.platforms.linux;
  };
})
