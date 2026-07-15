# This file defines overlays
{ inputs, ... }:
let
  # Common overlays applied to the unstable nixpkgs import.
  # Host-specific unstable overrides (e.g. for rocmSupport) should include these
  # to avoid losing package patches.
  unstableOverlays = [
    inputs.tinygrad-nix.overlays.default
    (uFinal: uPrev: {
      pulsemeeter = uPrev.pulsemeeter.overrideAttrs (oldAttrs: {
        src = uPrev.fetchFromGitHub {
          owner = "joegoldin";
          repo = "pulsemeeter";
          rev = "b87dd7f220e18f21795e1b718290c986b19c4907";
          hash = "sha256-B3wbAxL+6Tw83BwwvbGz4I+ZhaZSFpus/qlbxi9w8mw=";
        };
        patches = [ ];
      });

      # ibis-framework: duckdb import fails during pythonImportsCheck in nixpkgs
      python313Packages = uPrev.python313Packages.overrideScope (
        pyFinal: pyPrev: {
          ibis-framework = pyPrev.ibis-framework.overrideAttrs (old: {
            doInstallCheck = false;
            pythonImportsCheck = [ ];
          });
        }
      );

      # openldap: test017-syncreplication-refresh is timing-flaky in the sandbox
      # (esp. on i686 multilib pulled in by unstable.lutris)
      openldap = uPrev.openldap.overrideAttrs (old: {
        doCheck = false;
      });
    })
  ];
in
{
  inherit unstableOverlays;

  # This one brings our custom packages from the '_pkgs' directory
  additions = final: _prev: import ../_pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    # SunFounder robotics Python libs for the crawler (Robot HAT / PiCrawler).
    # Added to the python package set so they resolve via python3.withPackages.
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (pyFinal: _pyPrev: {
        robot-hat = pyFinal.callPackage ../_pkgs/sunfounder/robot-hat.nix { };
        sunfounder-controller = pyFinal.callPackage ../_pkgs/sunfounder/sunfounder-controller.nix { };
        picrawler = pyFinal.callPackage ../_pkgs/sunfounder/picrawler.nix { };
      })
    ];

    # direnv: fish integration test gets SIGKILL in the nix sandbox
    direnv = prev.direnv.overrideAttrs (old: {
      doCheck = false;
    });

    # openldap: test017-syncreplication-refresh is timing-flaky in the sandbox
    # (hardcoded 7s sleep waiting for syncrepl convergence)
    openldap = prev.openldap.overrideAttrs (old: {
      doCheck = false;
    });

    # xdg-desktop-portal: integration/inhibit::test_monitor and integration/usb
    # flake in the sandbox (dbus signal timing + missing USB devices) despite
    # XDP_TEST_IN_CI=1 already filtering known flakes upstream.
    xdg-desktop-portal = prev.xdg-desktop-portal.overrideAttrs (old: {
      doCheck = false;
    });

    # pipenv 2025.0.4 ships its sphinx docs/ (with conf.py) and benchmarks/
    # trees into site-packages, colliding with other Python envs in
    # home-manager-path's buildEnv merge.
    pipenv = prev.pipenv.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        rm -rf "$out"/lib/python*/site-packages/docs
        rm -rf "$out"/lib/python*/site-packages/benchmarks
      '';
    });

    # Force freerdp to use ffmpeg for H.264 instead of broken openh264
    freerdp = prev.freerdp.override { openh264 = null; };

    howdy = prev.howdy.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [
        (final.fetchpatch {
          url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/216245.patch";
          hash = "sha256-0N8xyCConfOfCNzSnoCHGlCSv6GQfpUQIwb/W5eQA0U=";
        })
      ];
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
        # torch-bin 2.12.0 marks itself "broken" whenever nixpkgs' cudaPackages
        # is older than the cuda-bindings>=13.0.3 it expects (currently 12.9.7).
        # That check is platform-agnostic, so it trips on aarch64-darwin too —
        # even though the macOS torch-bin wheel ships no CUDA at all. Downgrade
        # the false positive to a warning so the env still evaluates. Remove
        # once nixpkgs' default cudaPackages reaches >=13.0.3.
        problems.handlers.torch.unsupported-cuda-version = "warn";
      };
      overlays = unstableOverlays;
    };
  };

  # tinygrad with ROCm/CUDA/OpenCL support
  tinygrad-packages = inputs.tinygrad-nix.overlays.default;

  # Claude Desktop for Linux
  claude-desktop-packages = inputs.claude-desktop-debian.overlays.default;

  # LLM agent packages (claude-code, codex, antigravity) available as pkgs.llm-agents.*
  # Upstream dropped overlays.default (a passthrough of the flake's own
  # prebuilt packages), keeping only overlays.shared-nixpkgs, which rebuilds
  # everything against our nixpkgs and misses the numtide binary cache.
  # Replicate the old passthrough so the cache keeps hitting.
  llm-agents-packages = final: _prev: {
    llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
  };

  # audiomemo (recording + transcription CLI)
  audiomemo-packages = inputs.audiomemo.overlays.default;

  # sem (semantic, entity-level version control CLI) available as pkgs.sem
  sem-packages = final: _prev: {
    sem = inputs.sem.packages.${final.stdenv.hostPlatform.system}.default;
  };

  # claude-container (claude-code wrapper in docker container with sandboxing)
  claude-container-packages = inputs.claude-container.overlays.default;

  # affinity-nix (Affinity Photo/Designer/Publisher via wine)
  affinity-packages = inputs.affinity-nix.overlays.default;

  # MCP server packages for declarative MCP configuration
  # The upstream overlay only exports github-mcp-server; we also need mcp-language-server
  # Inlined upstream overlay to avoid deprecated pkgs.system access in mcps.overlays.default
  # NB: mcp-nixos is deliberately NOT overridden here; nixpkgs carries a
  # working (cached) mcp-nixos, while the mcps.nix-pinned 1.0.3 fails to build
  # (fastmcp dep). pkgs.mcp-nixos therefore resolves to nixpkgs' own package.
  mcps-packages =
    final: _prev:
    let
      unstable-pkgs = import inputs.mcps.inputs.nixpkgs-unstable {
        inherit (final.stdenv.hostPlatform) system;
      };
    in
    {
      inherit (unstable-pkgs) github-mcp-server;
      inherit (inputs.mcps.packages.${final.stdenv.hostPlatform.system}) mcp-language-server;
    };
}
