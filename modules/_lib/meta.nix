# Shared identity constants (replaces the username/useremail specialArgs).
# Plain attrset, not a module; the leading-underscore path keeps import-tree
# from loading it as a flake-parts module. Import it where needed:
#   meta = import ../_lib/meta.nix;
{
  username = "joe";
  email = "joe@joegold.in";
}
