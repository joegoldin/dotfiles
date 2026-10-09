{ inputs, pkgs }:
let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;
  toml = pkgs.formats.toml { };
  runtimePath = lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.jq
    pkgs.curl
    pkgs.git
    pkgs.openssh
    pkgs.ripgrep
  ];
  upstreamMemex = inputs.memex.packages.${system}.default;
  memex = pkgs.symlinkJoin {
    name = "memex-0.27.1";
    pname = "memex";
    version = "0.27.1";
    paths = [ upstreamMemex ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # Plugin commands start in the immutable store, not a writable checkout.
    postBuild = ''
      rm $out/bin/memex
      makeWrapper ${upstreamMemex}/bin/memex $out/bin/memex \
        --run 'export FASTEMBED_CACHE_DIR="''${FASTEMBED_CACHE_DIR:-''${XDG_CACHE_HOME:-$HOME/.cache}/memex/fastembed}"'
    '';
    inherit (upstreamMemex) meta;
  };
  ttt = inputs.ttt.packages.${system}.default.overrideAttrs (_: {
    version = "1.7.1";
    # Upstream uses the commit abbreviation even when built from a release tag.
    __intentionallyOverridingVersion = true;
    ldflags = [
      "-s"
      "-w"
      "-X main.version=1.7.1"
    ];
  });
  autoTitle = pkgs.buildGoModule {
    pname = "herdr-auto-title";
    version = "0.13.0";
    src = inputs.herdr-auto-title;
    vendorHash = "sha256-QxFp1b7pf7bn3Hh0hyaj8ke5Z61N+WwjhHt3pFiapTs=";
    subPackages = [ "cmd/herdr-auto-title" ];
    checkPhase = ''
      runHook preCheck
      go test ./...
      runHook postCheck
    '';
    meta = {
      description = "Local contextual tab and pane titles for Herdr";
      license = lib.licenses.mit;
      mainProgram = "herdr-auto-title";
    };
  };
  navigator = pkgs.rustPlatform.buildRustPackage {
    pname = "herdr-navigator";
    version = "0.3.6";
    src = inputs.herdr-navigator;
    cargoLock.lockFile = "${inputs.herdr-navigator}/Cargo.lock";
    # These test fixtures compare canonical paths; /tmp is a symlink on Darwin.
    postPatch = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      substituteInPlace src/app.rs src/sources.rs \
        --replace-fail '"/tmp"' '"/private/tmp"'
    '';
    meta = {
      description = "Fuzzy workspace and pane navigator for Herdr";
      license = lib.licenses.mit;
      mainProgram = "herdr-navigator";
    };
  };
  manifest = source: builtins.fromTOML (builtins.readFile "${source}/herdr-plugin.toml");
  plugin =
    name: source: settings: install:
    pkgs.runCommand name { } ''
      mkdir -p $out
      cp ${toml.generate "herdr-plugin.toml" settings} $out/herdr-plugin.toml
      cp ${source}/LICENSE $out/LICENSE
      ${install}
    '';
  memexManifest = manifest inputs.memex;
  titleManifest = manifest inputs.herdr-auto-title;
  navManifest = manifest inputs.herdr-navigator;
  tttManifest = manifest "${inputs.ttt}/herdr-plugin";
  tttLauncher = pkgs.writeShellScript "ttt-herdr-open-worktree" ''
    export PATH="${runtimePath}:$PATH"
    ${lib.replaceStrings [ "exec ttt" ] [ "exec ${ttt}/bin/ttt" ] (
      builtins.readFile "${inputs.ttt}/herdr-plugin/scripts/open-worktree.sh"
    )}
  '';
in
{
  inherit memex ttt;
  herdr-auto-title = autoTitle;
  herdr-navigator = navigator;

  herdr-memex-plugin =
    plugin "herdr-memex-plugin" inputs.memex
      (
        memexManifest
        // {
          build = [ ];
          actions = map (
            entry: entry // { command = [ "${pkgs.bash}/bin/bash" ] ++ builtins.tail entry.command; }
          ) memexManifest.actions;
          startup = map (
            entry: entry // { command = [ "${pkgs.bash}/bin/bash" ] ++ builtins.tail entry.command; }
          ) memexManifest.startup;
        }
      )
      ''
        cp -r ${inputs.memex}/herdr $out/herdr
        chmod -R u+w $out/herdr
        substituteInPlace $out/herdr/lib.sh \
          --replace-fail 'export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:''${PATH:-}"' \
            'export PATH="${runtimePath}:''${PATH:-}"'
        substituteInPlace $out/herdr/memex-pane.sh \
          --replace-fail '#!/usr/bin/env bash' '#!${pkgs.bash}/bin/bash'
        mkdir -p $out/bin
        ln -s ${memex}/bin/memex $out/bin/memex
      '';

  herdr-auto-title-plugin = plugin "herdr-auto-title-plugin" inputs.herdr-auto-title (
    titleManifest
    // {
      build = [ ];
      platforms = [
        "linux"
        "macos"
      ];
      startup = [ { command = [ "${autoTitle}/bin/herdr-auto-title" ]; } ];
      actions = map (
        entry:
        entry
        // {
          command = [
            "${autoTitle}/bin/herdr-auto-title"
            "restart"
          ];
        }
      ) titleManifest.actions;
    }
  ) "";

  herdr-navigator-plugin = plugin "herdr-navigator-plugin" inputs.herdr-navigator (
    navManifest
    // {
      build = [ ];
      actions = map (
        entry: entry // { command = [ "${navigator}/bin/herdr-navigator" ] ++ builtins.tail entry.command; }
      ) navManifest.actions;
      panes = map (
        entry: entry // { command = [ "${navigator}/bin/herdr-navigator" ] ++ builtins.tail entry.command; }
      ) navManifest.panes;
    }
  ) "";

  herdr-ttt-plugin = plugin "herdr-ttt-plugin" inputs.ttt (
    tttManifest
    // {
      build = [ ];
      actions = map (entry: entry // { command = [ "${tttLauncher}" ]; }) tttManifest.actions;
      panes = map (entry: entry // { command = [ "${tttLauncher}" ]; }) tttManifest.panes;
    }
  ) "";
}
