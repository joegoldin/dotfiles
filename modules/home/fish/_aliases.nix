{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  isLinux = pkgs.stdenv.isLinux;
in
{
  shellAliases = {
    # Hosts with the cli-packages aspect override this with the eza variant.
    ls = mkDefault "ls -lArth";
    l = "command ls";

    # macOS ships `open`; Linux uses `xdg-open` (routes dirs → Dolphin via XDG mime).
    open = mkIf isLinux "xdg-open";
  };

  shellAbbrs = {
    # Clear screen and scrollback
    clear = "printf '\\033[2J\\033[3J\\033[1;1H'";

    urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";

    n = "nix";
    nd = "nix develop --impure -c fish";
    ns = "nix shell";
    nsn = "nix shell nixpkgs#";
    nb = "nix build";
    nbn = "nix build nixpkgs#";
    nf = "nix flake";
  };
}
