{ config, pkgs, ... }:
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

  sdkRoot = "${androidSdk}/libexec/android-sdk";
  # cmdline-tools resolves this from XDG_CONFIG_HOME; the emulator binary does not,
  # so both have to be told explicitly or they disagree on where the AVDs live.
  androidUserHome = "${config.xdg.configHome}/.android";
in
{
  home.packages = [
    (unstable.androidStudioPackages.dev.withSdk androidSdk)
    androidSdk
    unstable.android-tools
  ];

  home.sessionVariables = {
    ANDROID_HOME = sdkRoot;
    ANDROID_SDK_ROOT = sdkRoot;
    ANDROID_USER_HOME = androidUserHome;
    ANDROID_AVD_HOME = "${androidUserHome}/avd";
  };
}
