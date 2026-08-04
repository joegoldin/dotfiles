{ pkgs, ... }:
let
  inherit (pkgs) unstable;
  androidSdk =
    (unstable.androidenv.composeAndroidPackages {
      platformVersions = [
        "36"
        "37"
      ];
      buildToolsVersions = [
        "36.0.0"
        "37.0.0"
      ];
      includeEmulator = true;
      includeSystemImages = true;
      systemImageTypes = [ "google_apis_playstore" ];
      abiVersions = [ "x86_64" ];
      includeNDK = true;
    }).androidsdk;
in
{
  home.packages = [
    (unstable.androidStudioPackages.dev.withSdk androidSdk)
    androidSdk
    unstable.android-tools
  ];
}
