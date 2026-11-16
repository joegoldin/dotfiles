# Evaluate with: import ./linux-tests.nix { inherit (pkgs) lib; }
{ lib }:
let
  package = {
    type = "derivation";
    name = "rex-rune";
    outPath = "/test/rex-rune";
    meta.mainProgram = "rex-rune";
  };
  module =
    (import ../rex-linux.nix {
      inputs.rex-rune.packages.x86_64-linux.default = package;
    }).den.aspects.rex-linux.homeManager;
  linux = module {
    inherit lib;
    config.xdg.configHome = "/config";
    pkgs.stdenv.hostPlatform = {
      system = "x86_64-linux";
      isLinux = true;
    };
  };
  darwin = module {
    inherit lib;
    config.xdg.configHome = "/config";
    pkgs.stdenv.hostPlatform = {
      system = "aarch64-darwin";
      isLinux = false;
    };
  };
in
lib.runTests {
  testLinuxEnabled = {
    expr = linux.condition;
    expected = true;
  };
  testLinuxPackage = {
    expr = map toString linux.content.home.packages;
    expected = [ "/test/rex-rune" ];
  };
  testDesktopUsesSharedFont = {
    expr = linux.content.xdg.desktopEntries."dev.shuv.rex-linux".exec;
    expected = ''/test/rex-rune/bin/rex-rune --font "TX02 Nerd Font Mono"'';
  };
  testDesktopDoesNotOpenAnotherTerminal = {
    expr = linux.content.xdg.desktopEntries."dev.shuv.rex-linux".terminal;
    expected = false;
  };
  testDesktopIdMatchesTaskbar = {
    expr = builtins.attrNames linux.content.xdg.desktopEntries;
    expected = [ "dev.shuv.rex-linux" ];
  };
  testMacDisabledWithoutMacPackage = {
    expr = darwin.condition;
    expected = false;
  };
  testNoServerService = {
    expr = linux.content ? systemd || linux.content ? launchd;
    expected = false;
  };
  testUpstreamDesktopIdentity = {
    expr = with linux.content.xdg.desktopEntries."dev.shuv.rex-linux"; [
      name
      icon
      settings.StartupWMClass
    ];
    expected = [
      "Rex Rune"
      "dev.shuv.rex-rune"
      "dev.shuv.rex-rune"
    ];
  };
  testNoObsoleteWorkspaceMigration = {
    expr = linux.content.home ? activation;
    expected = false;
  };
}
