develop:
	nix --extra-experimental-features nix-command --extra-experimental-features flakes develop --impure . -c fish

lint:
  nix fmt

check:
  nix flake check

devup:
	devenv up

build-wsl:
	sudo nixos-rebuild --flake .#joe-wsl switch

build-nixos:
	sudo nixos-rebuild --flake .#joe-nixos switch

build-macos:
	nix run --extra-experimental-features nix-command --extra-experimental-features flakes nix-darwin -- switch --flake .#Joes-MacBook-Air
