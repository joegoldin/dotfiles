{ pkgs, ... }:
let
  inherit (pkgs) unstable;
  androidSdk =
    (unstable.androidenv.composeAndroidPackages {
      platformVersions = [
        "35"
        "36"
      ];
      buildToolsVersions = [ "35.0.0" ];
      includeEmulator = true;
      includeSystemImages = true;
      systemImageTypes = [ "google_apis_playstore" ];
      abiVersions = [ "x86_64" ];
      includeNDK = true;
    }).androidsdk;
in
{
  home.packages = [
    (unstable.android-studio.withSdk androidSdk)
    unstable.android-tools
  ];
}
