[private]
default: system-info
  @just --list

[unix]
lint:
  @echo "📝  Linting Nix config..."
  @nix --extra-experimental-features 'nix-command flakes' fmt
  @echo "✅  Nix config linted!"

[unix]
check: lint flake-update
  @echo "🔍  Checking Nix config..."
  @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --all-systems
  @echo "✅  Flake check passed!"

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

build-zero2w-image:
  @echo "🔨  Building Nix image for Raspberry Pi Zero 2 W 🥧"
  @ssh joe@bastion.joegold.in -- "cd dotfiles; nix build -L .#nixosConfigurations.zero2w-printer.config.system.build.sdImage"
  @scp joe@bastion.joegold.in:/home/joe/dotfiles/result/sd-image/zero2.img .
  @echo "✅  Built for Raspberry Pi Zero 2 W!"

build-zero2w-remote:
  @echo "🔨  Building Nix config for Raspberry Pi Zero 2 W and deploying to remote 🥧"
  @nix run github:serokell/deploy-rs .#nixosConfigurations.zero2w-printer -- --ssh-user joe --hostname zero2w-printer.local
  @echo "✅  Built for Raspberry Pi Zero 2 W!"

[confirm]
[private]
build-macos: check
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
build-wsl: check
  @echo "🔨  Building Nix config for WSL 🪟"
  @sudo nixos-rebuild --flake .#joe-wsl switch
  @echo "✅  Built for WSL!"

[confirm]
[private]
build-bastion: check
  @echo "🔨  Building Nix config for NixOS on Oracle Cloud 🐧"
  @sudo nixos-rebuild --flake .#oracle-cloud-bastion switch
  @echo "✅  Built for NixOS on Oracle Cloud!"

[linux]
build: system-info
  @just {{ if shell('uname -r') =~ "WSL" { "build-wsl" } else { "build-bastion" } }}

system-info:
  @echo "🖥️  This is an {{arch()}} machine on {{os()}}"
