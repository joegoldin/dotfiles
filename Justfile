[private]
default: system-info
  @just --list

[unix]
lint:
  @echo "📝  Linting Nix config..."
  @nix --extra-experimental-features 'nix-command flakes' fmt
  @echo "✅  Nix config linted!"

[unix]
check-system:
  @echo "🔍  Checking Nix config for current system..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure

[unix]
flake-update:
  @echo "🔄  Updating flake..."
  @nix --extra-experimental-features 'nix-command flakes' flake update
  @echo "✅  Flake updated!"

[unix]
nix-gc:
  @echo "🧹  Garbage collecting nix..."
  @nix-env --delete-generations 14d
  @nix-store --gc
  @echo "✅  Garbage collected!"

[confirm]
[private]
build-macos: lint flake-update
  @echo "🔨  Building Nix config for macOS 🍎"
  @nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#Joes-MacBook-Pro
  @echo "✅  Built for macOS!"

[macos]
organize-launchpad:
  @echo "🔨  Organizing Launchpad..."
  @lporg load --config $(pwd)/environments/common/dotconfig/lporg.yaml --yes --no-backup
  @echo "✅  Organized Launchpad!"

[macos]
save-launchpad:
  @echo "🔨  Organizing Launchpad..."
  @lporg save --config $(pwd)/environments/common/dotconfig/lporg.yaml
  @echo "✅  Saved Launchpad!"

[macos]
build: system-info
  @just build-macos

[confirm]
[private]
build-wsl: lint flake-update
  @echo "🔍  Checking Nix config for WSL..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system x86_64-linux
  @echo "🔨  Building Nix config for WSL 🪟"
  @sudo nixos-rebuild --flake .#joe-wsl switch
  @echo "✅  Built for WSL!"

[confirm]
[private]
build-bastion: lint flake-update
  @echo "🔍  Checking Nix config for Oracle Cloud..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system x86_64-linux
  @echo "🔨  Building Nix config for NixOS on Oracle Cloud 🐧"
  @sudo nixos-rebuild --flake .#oracle-cloud-bastion switch
  @echo "✅  Built for NixOS on Oracle Cloud!"

[linux]
build: system-info
  @just {{ if shell('uname -r') =~ "WSL" { "build-wsl" } else { "build-bastion" } }}

system-info:
  @echo "🖥️  This is an {{arch()}} machine on {{os()}}"