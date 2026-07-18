# Firefox base-source hash for the version the current zen-src nightly targets
# (its surfer.json `version.version`). Auto-maintained by `just flake-update` —
# do NOT edit by hand.
#
# Why this exists: zen-src's own `nix/zen-browser.nix` reads the Firefox version
# from surfer.json but pins the source tarball hash manually, so when upstream
# bumps the Firefox base the nightly can ship a stale hash and the build dies
# with a fixed-output hash mismatch. `just flake-update` refreshes the pin below
# whenever zen updates; the zen module (default.nix) swaps in this source when
# `version` matches the base the current nightly targets.
{
  version = "152.0.6";
  sha512 = "sha512-xNh3g31wB/thHDjUnZtt07xMXJypALVOci4UDOfs0JJPabXO3H+MH+YC5+/h1xWbAZ3ieZnikjXNYxghuxPmsA==";
}
