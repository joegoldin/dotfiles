[private]
default: system-info
  @just --list

[unix]
lint:
  @echo "📝  Linting Nix config..."
  @nix --extra-experimental-features 'nix-command flakes' fmt
  @echo "✅  Nix config linted!"

[unix]
check-aarch64-darwin:
  @echo "🔍  Checking Nix config for aarch64-darwin..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system aarch64-darwin --show-trace
  @echo "✅  Check completed for aarch64-darwin!"

[unix]
check-x86_64-linux:
  @echo "🔍  Checking Nix config for x86_64-linux..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system x86_64-linux --show-trace
  @echo "✅  Check completed for x86_64-linux!"

[unix]
check-aarch64-linux:
  @echo "🔍  Checking Nix config for aarch64-linux..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system aarch64-linux --show-trace
  @echo "✅  Check completed for aarch64-linux!"

[unix]
check: system-info
  @if [ "$(arch)" = "aarch64" ] && [ "$(os)" = "macos" ]; then \
    just check-aarch64-darwin; \
  elif [ "$(arch)" = "x86_64" ] && [ "$(os)" = "linux" ]; then \
    just check-x86_64-linux; \
  elif [ "$(arch)" = "aarch64" ] && [ "$(os)" = "linux" ]; then \
    just check-aarch64-linux; \
  else \
    echo "Unsupported architecture and OS combination"; \
  fi

[unix]
flake-update:
  @echo "🔄  Updating flake..."
  @nix --extra-experimental-features 'nix-command flakes' flake update --option access-tokens "github.com=$(gh auth token)"
  @echo "✅  Flake updated!"

[unix]
update-pins dry_run='':
  @echo "🔄  Updating pinned flake inputs..."
  @{{ if dry_run == "--dry-run" { "DRY_RUN=true" } else { "" } }} scripts/update-flake-pins.sh
  @echo "✅  Pins updated!"

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
update-node-packages:
  @echo "🔄  Updating Node packages..."
  @scripts/update-node-packages.sh
  @echo "✅  Node packages updated!"

[unix]
nix-gc:
  @echo "🧹  Garbage collecting nix..."
  @nix-env --delete-generations 14d
  @nix-store --gc
  @nix-collect-garbage -d
  @echo "✅  Garbage collected!"

[private]
build-macos fast='':
  @echo "🔨  Building Nix config for macOS 🍎"
  @{{ if fast != "--fast" { "just lint flake-update" } else { "echo \"🚀 Fast mode, skipping checks...\"" } }}
  sudo darwin-rebuild switch --flake .#Joes-MacBook-Pro
  @echo "✅  Built for macOS!"

[macos]
build-macos-fast:
  @echo "🔨  Building Nix config for macOS 🍎 (fast mode)"
  sudo darwin-rebuild switch --flake .#Joes-MacBook-Pro
  @echo "✅  Built for macOS!"

[macos]
build-macos-initial:
  @echo "🔨  Building Nix config for macOS 🍎 (fast mode)"
  sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#Joes-MacBook-Pro
  @echo "✅  Built for macOS!"

[macos]
organize-launchpad:
  @echo "🔨  Organizing Launchpad..."
  @lporg load --config $(pwd)/hosts/common/system/dotconfig/lporg.yaml --yes --no-backup
  @echo "✅  Organized Launchpad!"

[macos]
save-launchpad:
  @echo "🔨  Organizing Launchpad..."
  @lporg save --config $(pwd)/hosts/common/system/dotconfig/lporg.yaml
  @echo "✅  Saved Launchpad!"

[macos]
build fast='': system-info
  @just build-macos {{fast}}

[private]
build-wsl fast='':
  @echo "🔨  Building Nix config for WSL 🪟"
  @{{ if fast != "--fast" { "just flake-update" } else { "echo \"🚀 Fast mode, skipping checks...\"" } }}
  @{{ if fast != "--fast" { "echo \"🔍  Checking Nix config for WSL...\"" } else { "" } }}
  @{{ if fast != "--fast" { "NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system x86_64-linux --show-trace" } else { "" } }}
  sudo nixos-rebuild --flake .#joe-wsl switch
  @echo "✅  Built for WSL!"

[private]
build-wsl-fast:
  @echo "🔨  Building Nix config for WSL 🪟 (fast mode)"
  sudo nixos-rebuild --flake .#joe-wsl switch
  @echo "✅  Built for WSL!"

[private]
build-bastion fast='':
  @echo "🔨  Building Nix config for NixOS on Oracle Cloud 🐧"
  @{{ if fast != "--fast" { "just lint flake-update" } else { "echo \"🚀 Fast mode, skipping checks...\"" } }}
  @{{ if fast != "--fast" { "echo \"🔍  Checking Nix config for Oracle Cloud...\"" } else { "" } }}
  @{{ if fast != "--fast" { "NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system aarch64-linux --show-trace" } else { "" } }}
  sudo nixos-rebuild --flake .#oracle-cloud-bastion switch
  @echo "✅  Built for NixOS on Oracle Cloud!"

[private]
build-bastion-fast:
  @echo "🔨  Building Nix config for NixOS on Oracle Cloud 🐧 (fast mode)"
  sudo nixos-rebuild --flake .#oracle-cloud-bastion switch
  @echo "✅  Built for NixOS on Oracle Cloud!"

[unix]
deploy-racknerd IP:
  @echo "🚀  Deploying Nix config to RackNerd VPS..."
  , nixos-anywhere --flake .#racknerd-cloud-agent --build-on local joe@{{IP}}
  @echo "✅  Deployed to RackNerd VPS!"

[unix]
rebuild-racknerd:
  @echo "🔨  Rebuilding NixOS on RackNerd VPS..."
  sudo nixos-rebuild switch --flake .#racknerd-cloud-agent
  @echo "✅  Rebuilt RackNerd VPS!"

[private]
build-nixos fast='':
  @echo "🔨  Building Nix config for NixOS 🐧"
  @{{ if fast != "--fast" { "just lint flake-update" } else { "echo \"🚀 Fast mode, skipping checks...\"" } }}
  @{{ if fast != "--fast" { "echo \"🔍  Checking Nix config for NixOS...\"" } else { "" } }}
  @{{ if fast != "--fast" { "NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system x86_64-linux --show-trace" } else { "" } }}
  sudo nixos-rebuild --flake .#joe-desktop switch
  @echo "✅  Built for NixOS!"

[private]
build-nixos-fast:
  @echo "🔨  Building Nix config for NixOS 🐧 (fast mode)"
  sudo nixos-rebuild --flake .#joe-desktop switch
  @echo "✅  Built for NixOS!"

[linux]
build fast='': system-info
  @if [[ "{{fast}}" != "" && "{{fast}}" != "-f" && "{{fast}}" != "--fast" ]]; then \
    echo "❌ Error: Invalid 'fast' parameter '{{fast}}'. Valid options are: empty, '-f', or '--fast'"; \
    exit 1; \
  fi
  @if uname -r | grep -q "WSL"; then \
    just build-wsl $([ "{{fast}}" = "-f" ] && echo "--fast" || echo "{{fast}}"); \
  elif [ "{{arch()}}" = "aarch64" ]; then \
    just build-bastion $([ "{{fast}}" = "-f" ] && echo "--fast" || echo "{{fast}}"); \
  elif [ "{{arch()}}" = "x86_64" ]; then \
    just build-nixos $([ "{{fast}}" = "-f" ] && echo "--fast" || echo "{{fast}}"); \
  else \
    echo "❌ Error: Unsupported architecture: {{arch()}}"; \
    exit 1; \
  fi

system-info:
  @echo "🖥️  This is an {{arch()}} machine on {{os()}}"
