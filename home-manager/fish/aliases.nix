{lib, config, ...}:
let
  inherit (lib) mkIf;
  packageNames = map (p: p.pname or p.name or null) config.home.packages;
  hasPackage = name: lib.any (x: x == name) packageNames;
  hasRipgrep = hasPackage "ripgrep";
  hasExa = hasPackage "eza";
  hasSpecialisationCli = hasPackage "specialisation";
  hasAwsCli = hasPackage "awscli2";
  hasKubectl = hasPackage "kubectl";
in
{
  shellAliases = rec {
	};

	shellAbbrs = {
		# Clear screen and scrollback
		clear = "printf '\\033[2J\\033[3J\\033[1;1H'";

		urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
		urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";

		n = "nix";
		nd = "nix develop -c $SHELL";
		ns = "nix shell";
		nsn = "nix shell nixpkgs#";
		nb = "nix build";
		nbn = "nix build nixpkgs#";
		nf = "nix flake";

		ga = "git add";
		gp = "git push";
		gc = "git commit";
		gd = "git diff";
		gf = "git fetch";
		gl = "git log";
		gs = "git status";

		snr = "sudo nixos-rebuild --flake .#joe-desktop";
		snrs = "sudo nixos-rebuild --flake .#joe-desktop switch";
		snrmac = "sudo nixos-rebuild --flake .#joe-macos";
		snrsmac = "sudo nixos-rebuild --flake .#joe-macos switch";

		s = mkIf hasSpecialisationCli "specialisation";

		ls = mkIf hasExa "eza";
		exa = mkIf hasExa "eza";
		lst = mkIf hasExa "eza -lath";

		awsswitch = mkIf hasAwsCli "export AWS_PROFILE=(aws configure list-profiles | fzf)";
		awslogin = mkIf hasAwsCli "aws sso login";

		k = mkIf hasKubectl "kubectl";
	};
}
