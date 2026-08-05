{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  udev,
}:
rustPlatform.buildRustPackage rec {
  pname = "litra";
  version = "3.3.0";

  src = fetchFromGitHub {
    owner = "timrogers";
    repo = "litra-rs";
    tag = "v${version}";
    hash = "sha256-cd6fg1rH7ZkUmYfdQoVQsypJgGwkvpmCvPrRpduMxSg=";
  };

  cargoHash = "sha256-Y7H448hG0/I7Ym6U+oX17XWTnVPW7ZA9l2w4fys6IhU=";

  # On Linux the hidapi crate builds its vendored C library against libudev
  # (linux-static-hidraw, its default backend); darwin goes through IOKit and
  # needs neither.
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ pkg-config ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ udev ];

  # Upstream ships udev rules giving the `video` group access to the Litra's
  # hidraw node; install them so `services.udev.packages = [ litra ]` works.
  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm444 99-litra.rules $out/lib/udev/rules.d/99-litra.rules
  '';

  meta = {
    description = "Control Logitech Litra lights from the command line";
    homepage = "https://github.com/timrogers/litra-rs";
    license = lib.licenses.mit;
    mainProgram = "litra";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
