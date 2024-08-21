[private]
default:
  @just --list

[unix]
lint:
  @echo "📝  Linting NixOS config..."
  @nix fmt
  @echo "✅  nix fmt passed!"

[unix]
check: lint flake-update
  @echo "🔍  Checking NixOS config..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix flake check --impure --all-systems
  @echo "✅  flake check passed!"

[unix]
flake-update:
  @echo "🔄  Updating flake..."
  @nix flake update

[confirm]
[private]
build-macos: check
  @echo "🔨  Building NixOS config for macOS 🍎"
  @nix run --extra-experimental-features 'nix-command flakes' nix-darwin -- switch --flake .#Joes-MacBook-Pro

[macos]
organize-launchpad:
  @echo "🔨  Organizing Launchpad..."
  @lporg load --config $(pwd)/environments/common/dotconfig/lporg.yaml --yes --no-backup

[macos]
save-launchpad:
  @echo "🔨  Organizing Launchpad..."
  @lporg save --config $(pwd)/environments/common/dotconfig/lporg.yaml

[macos]
build:
  @just build-macos

[confirm]
[private]
build-wsl: check
  @echo "🔨  Building NixOS config for WSL 🪟"
  @sudo nixos-rebuild --flake .#joe-wsl switch

[confirm]
[private]
build-bastion: check
  @echo "🔨  Building NixOS config for NixOS 🐧"
  @sudo nixos-rebuild --flake .#oracle-cloud-bastion switch

[linux]
build:
  @just {{ if shell('uname -r') =~ "WSL" { "build-wsl" } else { "build-bastion" } }}

system-info:
  @echo "🖥️  This is an {{arch()}} machine on {{os()}}"
