develop:
	nix develop --impure . -c fish

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
	sudo nixos-rebuild --flake .#joe-macos switch
