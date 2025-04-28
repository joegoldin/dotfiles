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
setup-python-packages packages='':
  @echo "🔄  Setting up Python packages..."
  @scripts/setup-python-packages.sh {{packages}}
  @echo "✅  Python packages setup!"

[unix]
update-python-packages:
  @echo "🔄  Updating Python packages..."
  @scripts/update-python-packages.sh --no-build
  @echo "✅  Python packages updated!"

[unix]
update-cursor-server:
  @echo "🔄  Updating Cursor server Linux..."
  @scripts/update-cursor-server-linux.fish
  @echo "✅  Cursor server updated!"

[unix]
nix-gc:
  @echo "🧹  Garbage collecting nix..."
  @nix-env --delete-generations 14d
  @nix-store --gc
  @echo "✅  Garbage collected!"

[confirm]
[private]
build-macos fast='':
  @echo "🔨  Building Nix config for macOS 🍎"
  @{{ if fast != "--fast" { "just lint flake-update" } else { "echo \"🚀 Fast mode, skipping checks...\"" } }}
  @nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#Joes-MacBook-Pro
  @echo "✅  Built for macOS!"

[macos]
build-macos-fast:
  @echo "🔨  Building Nix config for macOS 🍎 (fast mode)"
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
build fast='': system-info
  @just build-macos {{fast}}

[confirm]
[private]
build-wsl fast='':
  @echo "🔨  Building Nix config for WSL 🪟"
  @{{ if fast != "--fast" { "just lint flake-update" } else { "echo \"🚀 Fast mode, skipping checks...\"" } }}
  @{{ if fast != "--fast" { "echo \"🔍  Checking Nix config for WSL...\"" } else { "" } }}
  @{{ if fast != "--fast" { "NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system x86_64-linux" } else { "" } }}
  @sudo nixos-rebuild --flake .#joe-wsl switch
  @echo "✅  Built for WSL!"

[private]
build-wsl-fast:
  @echo "🔨  Building Nix config for WSL 🪟 (fast mode)"
  @sudo nixos-rebuild --flake .#joe-wsl switch
  @echo "✅  Built for WSL!"

[confirm]
[private]
build-bastion fast='':
  @echo "🔨  Building Nix config for NixOS on Oracle Cloud 🐧"
  @{{ if fast != "--fast" { "just lint flake-update" } else { "echo \"🚀 Fast mode, skipping checks...\"" } }}
  @{{ if fast != "--fast" { "echo \"🔍  Checking Nix config for Oracle Cloud...\"" } else { "" } }}
  @{{ if fast != "--fast" { "NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system x86_64-linux" } else { "" } }}
  @sudo nixos-rebuild --flake .#oracle-cloud-bastion switch
  @echo "✅  Built for NixOS on Oracle Cloud!"

[private]
build-bastion-fast:
  @echo "🔨  Building Nix config for NixOS on Oracle Cloud 🐧 (fast mode)"
  @sudo nixos-rebuild --flake .#oracle-cloud-bastion switch
  @echo "✅  Built for NixOS on Oracle Cloud!"

[linux]
build fast='': system-info
  @if [[ "{{fast}}" != "" && "{{fast}}" != "-f" && "{{fast}}" != "--fast" ]]; then \
    echo "❌ Error: Invalid 'fast' parameter '{{fast}}'. Valid options are: empty, '-f', or '--fast'"; \
    exit 1; \
  fi
  @just {{ if shell('uname -r') =~ "WSL" { "build-wsl" } else { "build-bastion" } }} {{ if fast == "-f" { "--fast" } else { fast } }}

system-info:
  @echo "🖥️  This is an {{arch()}} machine on {{os()}}"
