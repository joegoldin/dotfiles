{
  lib,
  pam-watchid,
  pamWatchidSource,
  openpam,
  python3,
  writeTextDir,
}:
let
  # Apple ships libpam in the dyld cache, but the Nix SDK omits its link stub.
  # Bind only the public functions we use to Apple's exact install name.
  systemPam = writeTextDir "lib/libpam.tbd" ''
    --- !tapi-tbd
    tbd-version: 4
    targets: [ arm64-macos, x86_64-macos ]
    install-name: '/usr/lib/libpam.2.dylib'
    current-version: 1.0.0
    compatibility-version: 1.0.0
    exports:
      - targets: [ arm64-macos, x86_64-macos ]
        symbols: [ _pam_get_data, _pam_get_item ]
    ...
  '';
in
pam-watchid.overrideAttrs (old: {
  version =
    if pamWatchidSource ? rev then
      "2-unstable-${builtins.substring 0 7 pamWatchidSource.rev}"
    else
      "2-local";
  src = lib.cleanSourceWith {
    src = pamWatchidSource;
    filter =
      path: type:
      lib.cleanSourceFilter path type
      && !(lib.elem (baseNameOf path) [
        ".build"
        "__pycache__"
      ]);
  };
  # The Nix SDK omits PAM headers. Use OpenPAM's declarations, but do not add
  # its library search path: sudo's handles belong to Apple's system libpam.
  env = (old.env or { }) // {
    NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -isystem ${openpam}/include";
    NIX_LDFLAGS = (old.env.NIX_LDFLAGS or "") + " -L${systemPam}/lib";
  };
  nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ python3 ];
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    python3 Tests/test_timeout.py
    runHook postCheck
  '';
})
