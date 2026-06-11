# Verbatim reconstruction of the old flake.nix `commonSpecialArgs`, used to
# bridge the legacy module trees under hosts/ into den entities: each host
# overrides den's `instantiate` to inject these specialArgs (OS eval) and
# passes them as home-manager.extraSpecialArgs (hm eval) — the exact two
# mechanisms the old flake used.
#
# TRANSITIONAL: every key here dies when the last hosts/ module stops
# consuming it (target: aspects close over `inputs`/`config` and import
# modules/_lib/meta.nix instead). Underscore path = invisible to import-tree.
{ inputs }:
let
  inherit (inputs)
    self
    nixpkgs
    dotfiles-assets
    dotfiles-secrets
    ;
  inherit (self) outputs;
  meta = import ./meta.nix;
  username = meta.username;
  useremail = meta.email;
  hostname = "${username}-nix";
  homeDirectory = nixpkgs.lib.mkForce "/home/${username}";
  stateVersion = "24.11";
  commonOverlays = builtins.attrValues self.overlays;
  keys = import "${dotfiles-secrets}/keys.nix";
in
inputs
// {
  inherit
    inputs
    outputs
    commonOverlays
    useremail
    stateVersion
    username
    hostname
    homeDirectory
    dotfiles-assets
    dotfiles-secrets
    keys
    ;
}
