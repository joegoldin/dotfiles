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
[macos]
build: lint check
  @echo "🔨  Building NixOS config for macOS 🍎  ({{os()}})"
  @nix run --extra-experimental-features 'nix-command flakes' nix-darwin -- switch --flake .#Joes-MacBook-Air

[confirm]
[private]
build-wsl: lint check
  @echo "🔨  Building NixOS config for WSL 🪟  ({{os()}})"
  @sudo nixos-rebuild --flake .#joe-wsl switch

[confirm]
[private]
build-nixos: lint check
  @echo "🔨  Building NixOS config for NixOS 🐧  ({{os()}})"
  @sudo nixos-rebuild --flake .#joe-nixos switch

[linux]
build:
  @just {{ if "{{shell('uname -r')}}" =~ "WSL" { "build-wsl" } else { "build-nixos" } }}

system-info:
  @echo "🖥️  This is an {{arch()}} machine on {{os()}}"
