# Evaluate with: import ./linux-tests.nix { inherit (pkgs) lib; }
{ lib }:
let
  package = {
    type = "derivation";
    name = "rex-linux";
    outPath = "/test/rex-linux";
    meta.mainProgram = "rex-linux";
  };
  module =
    (import ../rex-linux.nix {
      inputs.rex-rune.packages.x86_64-linux.default = package;
    }).den.aspects.rex-linux.homeManager;
  linux = module {
    inherit lib;
    pkgs.stdenv.hostPlatform = {
      system = "x86_64-linux";
      isLinux = true;
    };
  };
  darwin = module {
    inherit lib;
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
    expected = [ "/test/rex-linux" ];
  };
  testDesktopUsesSharedFont = {
    expr = linux.content.xdg.desktopEntries."dev.shuv.rex-linux".exec;
    expected = ''/test/rex-linux/bin/rex-linux --font "TX02 Nerd Font Mono"'';
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
  testNoActivation = {
    expr = linux.content.home ? activation;
    expected = false;
  };
}
