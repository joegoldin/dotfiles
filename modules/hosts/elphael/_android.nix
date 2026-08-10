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

  # Android Studio bakes an absolute SDK path into its own config and never
  # revisits it, so a bare store path breaks the moment the SDK is rebuilt and
  # the old one is garbage-collected. Everything points at this stable symlink
  # instead, which home-manager re-aims on each rebuild.
  sdkLink = ".local/share/android-sdk";
  stableSdk = "${config.home.homeDirectory}/${sdkLink}";

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

  home.file.${sdkLink}.source = sdkRoot;

  home.sessionVariables = {
    ANDROID_HOME = stableSdk;
    ANDROID_SDK_ROOT = stableSdk;
    ANDROID_USER_HOME = androidUserHome;
    ANDROID_AVD_HOME = "${androidUserHome}/avd";
  };
}
