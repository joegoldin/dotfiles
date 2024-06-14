lint:
  @echo "📝  Linting NixOS config..."
  @nix fmt
  @echo "✅  nix fmt passed!"

check: lint
  @echo "🔍  Checking NixOS config..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix flake check --impure --all-systems
  @echo "✅  flake check passed!"

build-wsl: lint check
  @echo "🔨  Building NixOS config for WSL 🪟  ({{os()}})"
  @sudo nixos-rebuild --flake .#joe-wsl switch

build-nixos: lint check
  @echo "🔨  Building NixOS config for NixOS 🐧  ({{os()}})"
  @sudo nixos-rebuild --flake .#joe-nixos switch

build-macos: lint check
  @echo "🔨  Building NixOS config for macOS 🍎  ({{os()}})"
  @nix run --extra-experimental-features 'nix-command flakes' nix-darwin -- switch --flake .#Joes-MacBook-Air

system := shell('uname -r')
linux_target := if system =~ "WSL" { "build-wsl" } else { "build-nixos" }
target := if "{{os()}}" =~ "macos" { "build-macos" } else { linux_target }
build: system-info
  @just {{target}}

system-info:
  @echo "🖥️  This is an {{arch()}} machine on {{os()}}/{{system}}"
