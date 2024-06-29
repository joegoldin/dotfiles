[private]
default:
  @just --list

[unix]
lint:
  @echo "📝  Linting NixOS config..."
  @nix fmt
  @echo "✅  nix fmt passed!"

[unix]
check: lint
  @echo "🔍  Checking NixOS config..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix flake check --impure --all-systems
  @echo "✅  flake check passed!"

[confirm]
[private]
build-macos: lint check
  @echo "🔨  Building NixOS config for macOS 🍎"
  @nix run --extra-experimental-features 'nix-command flakes' nix-darwin -- switch --flake .#Joes-MacBook-Pro

[macos]
organize-launchpad:
  @echo "🔨  Organizing Launchpad..."
  @lporg load --config ~/.config/lporg.yaml --yes --no-backup

[macos]
build:
  @just build-macos
  @just organize-launchpad

[confirm]
[private]
build-wsl: lint check
  @echo "🔨  Building NixOS config for WSL 🪟"
  @sudo nixos-rebuild --flake .#joe-wsl switch

[confirm]
[private]
build-nixos: lint check
  @echo "🔨  Building NixOS config for NixOS 🐧"
  @sudo nixos-rebuild --flake .#joe-nixos switch

[linux]
build:
  @just {{ if shell('uname -r') =~ "WSL" { "build-wsl" } else { "build-nixos" } }}

system-info:
  @echo "🖥️  This is an {{arch()}} machine on {{os()}}"
