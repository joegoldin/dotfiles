{
  description = "Joe Goldin Nix Config";

  inputs = {
    # ── Dendritic core ──────────────────────────────────────────────────────
    # Every file under modules/ is a flake-parts module (the dendritic
    # pattern, https://github.com/mightyiam/dendritic). import-tree loads the
    # whole tree (paths containing "/_" are skipped); den layers an
    # aspect-oriented entity model on top. See README.md.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    den.url = "github:denful/den";
    # Dynamic derivations; the IFD replacement (build-time nix eval without
    # import-from-derivation). Consumed as inputs.drowse.lib.${system}; hosts
    # opt in to the required experimental features via
    # den.aspects.dynamic-derivations.
    drowse = {
      url = "github:figsoda/drowse";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Nixpkgs ─────────────────────────────────────────────────────────────
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";

    # Zen built from source via buildMozillaMach. Points at the fork's `nightly`
    # branch ("dev as if all my open PRs were merged"), rebuilt by the
    # nightly-integration GitHub Action (dev + every conflict-free PR). Pinned
    # in flake.lock; bump with `nix flake update zen-src` when you want the
    # latest nightly. Intentionally pins its OWN nixpkgs (matched to the fork's
    # Firefox version) rather than following ours, so a system nixpkgs bump can't
    # drift the Firefox base out from under buildMozillaMach's patches.
    zen-src.url = "github:joegoldin/zen-browser-desktop/nightly";

    # ── Core framework ─────────────────────────────────────────────────────
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # jovian (Steam Deck)
    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # NixOS on Raspberry Pi: kernel, firmware, bootloader, sd-image, optimized
    # vendor packages (libcamera, ffmpeg). Tracks develop; follows our nixpkgs
    # so the Pi builds on nixos-26.05 (its cachix kernel won't match, so the
    # kernel builds from source — fine, built natively on the Mac via virby).
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Personal data repos (ssh) ──────────────────────────────────────────
    # assets (fonts, sfx, etc.); bump with `nix flake update dotfiles-assets`
    dotfiles-assets = {
      url = "git+ssh://git@github.com/joegoldin/dotfiles-assets";
      flake = false;
    };
    # secrets (domains, encrypted age files, etc.); private repo over ssh;
    # bump with `nix flake update dotfiles-secrets`
    dotfiles-secrets = {
      url = "git+ssh://git@github.com/joegoldin/dotfiles-secrets";
      flake = false;
    };

    # ── My repos ─────────────────────────────────────────────────────────────
    # recording + transcription CLI
    audiomemo = {
      url = "github:joegoldin/audiomemo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # claude-code wrapper in docker container with sandboxing
    claude-container = {
      url = "github:joegoldin/claude-container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # CIT200 desk phone; reactive dataflow engine
    desk-phone = {
      url = "github:joegoldin/desk-phone-cit200";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # PiCrawler AI brain (robotd MCP body + pi agent); private repo over ssh;
    # bump with `nix flake update crawler`. Imported by the crawler host's
    # brain.nix aspect (services.crawler-brain).
    crawler = {
      url = "git+ssh://git@github.com/joegoldin/crawler";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Server services ────────────────────────────────────────────────────
    # binary cache server
    attic = {
      url = "github:joegoldin/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # attic infrastructure (client modules, post-build hooks)
    nix-attic-infra = {
      url = "github:joegoldin/nix-attic-infra";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.attic.follows = "attic";
    };
    # game server management
    pelican = {
      url = "github:Hythera/nix-pelican";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Nix utilities ──────────────────────────────────────────────────────
    flake-utils.url = "github:numtide/flake-utils";
    systems.url = "github:nix-systems/default";
    # agenix
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # microVM runtime (for the `vm` CLI)
    microvm-nix = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # declarative flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    # pre-built nix-index database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # vfkit-based linux builder for nix-darwin (replaces the rosetta-builder)
    virby = {
      url = "github:quinneden/virby-nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Development tools ──────────────────────────────────────────────────
    devenv.url = "github:cachix/devenv";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    git-hooks.url = "github:cachix/git-hooks.nix";

    # ── ML / GPU compute ────────────────────────────────────────────────────
    # tinygrad with ROCm/CUDA support
    tinygrad-nix = {
      url = "github:joegoldin/tinygrad-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # ── Desktop / NixOS applications ───────────────────────────────────────
    # affinity apps
    affinity-nix = {
      url = "github:mrshmllow/affinity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Ghostty terminal
    ghostty.url = "github:ghostty-org/ghostty";
    # Zed editor (built from source via flake)
    zed-editor.url = "github:zed-industries/zed";
    # Zed nix extension (fork with language injection for script bodies)
    zed-nix-ext = {
      url = "github:joegoldin/zed-extensions-nix";
      flake = false;
    };
    # KDE configuration
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # ── Claude / LLM tooling ───────────────────────────────────────────────
    # Claude Desktop for Linux.
    # TEMP-PINNED (the one exception to the no-URL-pins rule): HEAD's
    # d2ce0466 bumps Claude Desktop to 1.12603.1, where the .asar --add-dir
    # filter patch fails ("pattern matches 2 times"); no fix PR upstream
    # yet. e85450c9 = last rev before the bump (app 1.11847.5, includes the
    # PR #666 patch fix). Unpin once upstream builds again.
    claude-desktop-debian = {
      url = "github:aaddrick/claude-desktop-debian/e85450c90ba38159f89f02bdd0f6c6d7e6bce065";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # LLM agent tools (claude-code, codex, antigravity)
    llm-agents.url = "github:numtide/llm-agents.nix";
    # declarative MCP server configuration
    mcps = {
      url = "github:roman/mcps.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # Agent skills + re-exported claude-nix, antigravity-cli-nix, codex-nix
    # modules; over ssh; bump with `nix flake update agent-skills`
    agent-skills = {
      url = "git+ssh://git@github.com/joegoldin/agent-skills";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Homebrew (macOS) ───────────────────────────────────────────────────
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.follows = "brew-src";
    };
    # Homebrew itself, tracking master: macOS 27 support (golden_gate: "27")
    # is only on master; release tags top out at tahoe/26 and raise `unknown
    # or unsupported macOS version: :dunno` during `brew bundle`.
    brew-src = {
      url = "github:Homebrew/brew";
      flake = false;
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };

    # Official taps
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "";
    extra-substituters = "";
    experimental-features = "nix-command flakes";
  };

  # The dendritic entry point: everything else lives in modules/.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
