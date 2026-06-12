{
  description = "Joe Goldin Nix Config";

  inputs = {
    self.submodules = true;

    # ── Dendritic core ──────────────────────────────────────────────────────
    # Every file under modules/ is a flake-parts module (the dendritic
    # pattern, https://github.com/mightyiam/dendritic). import-tree loads the
    # whole tree (paths containing "/_" are skipped); den layers an
    # aspect-oriented entity model on top. See MIGRATION.md.
    flake-parts = {
      url = "github:hercules-ci/flake-parts?rev=f7c1a2d347e4c52d5fb8d10cb4d94b5884e546fb";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree?rev=d321337efd0f23a9eb14a42adb7b2c29313ab274";
    den.url = "github:denful/den?rev=fe63b4bff3358e51687b6f88fa8746d5b3dc1bd5";
    # Dynamic derivations — the IFD replacement (build-time nix eval without
    # import-from-derivation). Consumed as inputs.drowse.lib.${system}; hosts
    # opt in to the required experimental features via
    # den.aspects.dynamic-derivations.
    drowse = {
      url = "github:figsoda/drowse?rev=f63dc21e120c17cbed472119097c2ecc6ef37a0a";
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
    # branch — "dev as if all my open PRs were merged" — rebuilt by the
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
      url = "github:Jovian-Experiments/Jovian-NixOS?rev=255a964247cd3bcc68947b675ce270212e98568f";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Local sources ───────────────────────────────────────────────────────
    # assets (fonts, etc.)
    dotfiles-assets = {
      url = "./assets";
      flake = false;
    };
    # secrets (domains, encrypted age files, etc.) — private repo over ssh;
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
    # CIT200 desk phone — reactive dataflow engine
    desk-phone = {
      url = "github:joegoldin/desk-phone-cit200";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # game server management
    pelican = {
      url = "github:joegoldin/nix-pelican?rev=900716d90d01a27666d65c9c112acde4c725ae9f";
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

    # ── Nix utilities ──────────────────────────────────────────────────────
    flake-utils.url = "github:numtide/flake-utils?ref=v1.0.0";
    systems.url = "github:nix-systems/default?rev=da67096a3b9bf56a91d16901293e51ba5b49a27e";
    # agenix
    agenix = {
      url = "github:ryantm/agenix?rev=b027ee29d959fda4b60b57566d64c98a202e0feb";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # disko
    disko = {
      url = "github:nix-community/disko?ref=v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # microVM runtime (for the `vm` CLI)
    microvm-nix = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # declarative flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
    # pre-built nix-index database
    nix-index-database = {
      url = "github:nix-community/nix-index-database?rev=1a2ea89c917781e88508d9fd2b507f2d2a0e173c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # vfkit-based linux builder for nix-darwin (replaces the rosetta-builder)
    virby = {
      url = "github:quinneden/virby-nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Development tools ──────────────────────────────────────────────────
    devenv.url = "github:cachix/devenv?ref=v2.1.2";
    nixpkgs-python.url = "github:cachix/nixpkgs-python?rev=5030393c8dfde39bddef22ef7e0415f687a96e8f";
    git-hooks.url = "github:cachix/git-hooks.nix?rev=61ab0e80d9c7ab14c256b5b453d8b3fb0189ba0a";

    # ── ML / GPU compute ────────────────────────────────────────────────────
    # tinygrad with ROCm/CUDA support
    tinygrad-nix = {
      url = "github:joegoldin/tinygrad-nix?rev=99c52bfdc5108c08d26d3d379368f9abd9d96b4d";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # ── Desktop / NixOS applications ───────────────────────────────────────
    # affinity apps
    affinity-nix = {
      url = "github:mrshmllow/affinity-nix?rev=7f462d47a0cd86878ae3c2e9f2813a03d72935a0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Ghostty terminal
    ghostty.url = "github:ghostty-org/ghostty?rev=69095e298ab88bb0eb5ba541f4c505f2c22d07f5";
    # Zed editor (built from source via flake)
    zed-editor.url = "github:zed-industries/zed?ref=v1.6.2-pre";
    # Zed nix extension (fork with language injection for script bodies)
    zed-nix-ext = {
      url = "github:joegoldin/nix";
      flake = false;
    };
    # KDE configuration
    plasma-manager = {
      url = "github:nix-community/plasma-manager?rev=a524a6160e6df89f7673ba293cf7d78b559eb1a5";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # ── Claude / LLM tooling ───────────────────────────────────────────────
    # Claude Desktop for Linux.
    # TEMP: pinned to DhanushSantosh's fork PR #666 head, which retargets
    # the .asar trusted-folder guard injection to the `async
    # addTrustedFolder(...) {` body. The old aaddrick rev (2ae2172a) failed
    # to build Claude Desktop 1.9659.2 with "addTrustedFolder anchor not
    # found". Revert to `aaddrick/claude-desktop-debian` main once
    # https://github.com/aaddrick/claude-desktop-debian/pull/666 merges.
    claude-desktop-debian = {
      url = "github:DhanushSantosh/claude-desktop-debian/8667552c3cc3991a9691ee44eeeaabc5b809bbc5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # LLM agent tools (claude-code, codex, antigravity)
    llm-agents.url = "github:numtide/llm-agents.nix?rev=af2ff595989e83142d2abd0a81bf6e582b248058";
    # declarative MCP server configuration
    mcps = {
      url = "github:roman/mcps.nix?rev=25acc4f20f5928a379e80341c788d80af46474b1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # Agent skills + re-exported claude-nix, antigravity-cli-nix, codex-nix
    # modules — over ssh; bump with `nix flake update agent-skills`
    agent-skills = {
      url = "git+ssh://git@github.com/joegoldin/agent-skills";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Homebrew (macOS) ───────────────────────────────────────────────────
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew?rev=562332f97de9f5ba51aa647d70462e88222b2988";
      inputs.brew-src.follows = "brew-src";
    };
    # Homebrew itself, pinned past the 5.1.x releases: macOS 27 support
    # (golden_gate: "27") is only on master — every release tag still tops out
    # at tahoe/26 and raises `unknown or unsupported macOS version: :dunno`
    # during `brew bundle`. Bump with `nix flake update brew-src`.
    brew-src = {
      url = "github:Homebrew/brew?rev=259096ec10414b11b01561706c1debb37e631ce8";
      flake = false;
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix?rev=d40695006e0313d131c668d926d92c0fcd737e2a";
      inputs.brew-api.follows = "brew-api";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };

    # NOTE: mac-app-util (Spotlight/Dock trampolines for Nix-installed .apps)
    # was removed: it's written in Common Lisp and SBCL (even 2.6.4) cannot
    # mmap its dynamic space on macOS 27 ("failed to allocate ... at
    # 0x300100000"). Casks live on Homebrew in /Applications anyway. Re-add
    # once SBCL runs on macOS 27.

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
