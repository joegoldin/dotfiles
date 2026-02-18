{
  # assets (fonts, etc.)
  dotfiles-assets = {
    url = "git+file:assets";
    flake = false;
  };
  # secrets (domains, encrypted age files, etc.)
  dotfiles-secrets = {
    url = "git+file:secrets";
    flake = false;
  };
  # Nixpkgs
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  # You can access packages and modules from different nixpkgs revs
  # at the same time. Here's an working example:
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
  nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
  # darwin
  nix-darwin = {
    url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # Home manager
  home-manager = {
    url = "github:nix-community/home-manager/release-25.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # wsl
  nixos-wsl.url = "github:nix-community/NixOS-WSL/release-25.11";
  # flake-utils
  flake-utils.url = "github:numtide/flake-utils?ref=v1.0.0";
  # systems
  systems.url = "github:nix-systems/default?rev=da67096a3b9bf56a91d16901293e51ba5b49a27e";
  # devenv
  devenv.url = "github:cachix/devenv?ref=v1.11.2";
  # nixpkgs-python
  nixpkgs-python.url = "github:cachix/nixpkgs-python?rev=04b27dbad2e004cb237db202f21154eea3c4f89f";
  # pre-commit-hooks
  pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix?rev=b68b780b69702a090c8bb1b973bab13756cc7a27";
  # brew-nix
  brew-nix = {
    url = "github:BatteredBunny/brew-nix?rev=b314426c17667bcebd73ed7e57ecae2bac9755cf";
    inputs.brew-api.follows = "brew-api";
  };
  brew-api = {
    url = "github:BatteredBunny/brew-api";
    flake = false;
  };
  # nix-homebrew
  nix-homebrew.url = "github:zhaofengli/nix-homebrew?rev=6a8ab60bfd66154feeaa1021fc3b32684814a62a";
  # Homebrew taps
  homebrew-core = {
    url = "github:homebrew/homebrew-core";
    flake = false;
  };
  homebrew-cask = {
    url = "github:homebrew/homebrew-cask";
    flake = false;
  };
  homebrew-services = {
    url = "github:homebrew/homebrew-services";
    flake = false;
  };
  homebrew-bundle = {
    url = "github:homebrew/homebrew-bundle";
    flake = false;
  };
  # Additional taps
  homebrew-argoproj = {
    url = "github:argoproj/homebrew-tap";
    flake = false;
  };
  homebrew-assemblyai = {
    url = "github:assemblyai/homebrew-assemblyai";
    flake = false;
  };
  homebrew-k9s = {
    url = "github:derailed/homebrew-k9s";
    flake = false;
  };
  homebrew-ibigio = {
    url = "github:ibigio/homebrew-tap";
    flake = false;
  };
  homebrew-vd = {
    url = "github:saulpw/homebrew-vd";
    flake = false;
  };
  homebrew-ocr = {
    url = "github:schappim/homebrew-ocr";
    flake = false;
  };
  homebrew-skip = {
    url = "github:skiptools/homebrew-skip";
    flake = false;
  };
  homebrew-txn2 = {
    url = "github:txn2/homebrew-tap";
    flake = false;
  };
  homebrew-versent = {
    url = "github:versent/homebrew-taps";
    flake = false;
  };
  homebrew-blacktop = {
    url = "github:blacktop/homebrew-tap";
    flake = false;
  };
  homebrew-cirruslabs = {
    url = "github:cirruslabs/homebrew-cli";
    flake = false;
  };
  homebrew-neilberkman = {
    url = "github:neilberkman/homebrew-clippy";
    flake = false;
  };
  #disko
  disko = {
    url = "github:nix-community/disko?ref=v1.13.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # agenix
  agenix = {
    url = "github:ryantm/agenix?rev=fcdea223397448d35d9b31f798479227e80183f6";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # plasma-manager for KDE configuration
  plasma-manager = {
    url = "github:nix-community/plasma-manager?rev=51816be33a1ff0d4b22427de83222d5bfa96d30e";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };
  # affinity apps
  affinity-nix = {
    url = "github:mrshmllow/affinity-nix?rev=0c110a15fb5605490f7de451073db1c775745fee";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # for mkWindowsApp
  erosanix = {
    url = "github:emmanuelrosa/erosanix?rev=ce9b9a671ace6e1c446bcfd3e24a17a3674d04ca";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # for secure boot
  lanzaboote = {
    url = "github:nix-community/lanzaboote/v1.0.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # LLM agent tools (claude-code, codex, gemini-cli)
  llm-agents.url = "github:numtide/llm-agents.nix?rev=398181e94b91ad081fad17d9b5eab140411d6a29";
  # superpowers (Claude Code skills)
  superpowers = {
    url = "github:obra/superpowers?ref=v4.0.3";
    flake = false;
  };
  # claude-nix (Claude Code configuration library)
  claude-nix = {
    url = "github:joegoldin/claude-nix?rev=337e48e08076a01c12a00290a318955e5e8bd6d2";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # mcps.nix (declarative MCP server configuration)
  mcps = {
    url = "github:roman/mcps.nix?rev=25acc4f20f5928a379e80341c788d80af46474b1";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };
  # pelican panel (game server management)
  pelican = {
    url = "github:joegoldin/nix-pelican?rev=900716d90d01a27666d65c9c112acde4c725ae9f";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # nix-rosetta-builder for fast x86_64-linux builds on Apple Silicon
  nix-rosetta-builder = {
    url = "github:cpick/nix-rosetta-builder?rev=ebb7162a975074fb570a2c3ac02bc543ff2e9df4";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # audiotools (recording + transcription CLI)
  audiotools = {
    url = "github:joegoldin/audiotools";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # nix-flatpak for declarative flatpak management
  nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
}
