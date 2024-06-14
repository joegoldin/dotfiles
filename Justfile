develop:
  @nix --extra-experimental-features nix-command --extra-experimental-features flakes develop --impure . -c fish

lint:
  @echo "📝 Linting NixOS config..."
  @nix fmt
  @echo "✅ nix fmt passed!"

check: lint
  @echo "🔍 Checking NixOS config..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix flake check --impure --all-systems
  @echo "✅ flake check passed!"

devup:
  @devenv up

build-wsl:
  @echo "🔨 Building NixOS config for WSL 🪟 ({{os()}})"
  @sudo nixos-rebuild --flake .#joe-wsl switch

build-nixos:
  @echo "🔨 Building NixOS config for NixOS 🐧 ({{os()}})"
  @sudo nixos-rebuild --flake .#joe-nixos switch

build-macos: lint check
  @echo "🔨 Building NixOS config for macOS 🍎 ({{os()}})"
  @nix run --extra-experimental-features 'nix-command flakes' nix-darwin -- switch --flake .#Joes-MacBook-Air

target := if "{{os()}}" == "macos" { "build-macos" } else { "build-wsl" }
build:
  @echo "🧱 Building on {{os()}}..."
  @just {{target}}
