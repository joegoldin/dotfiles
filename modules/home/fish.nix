# fish + atuin + fish-ai. The module tree lives in ./_hm/fish (invisible to
# import-tree); dotfiles-secrets reaches it via the module-args shim
# (modules/nix/module-args.nix).
{ ... }:
{
  den.aspects.fish.homeManager = ./_hm/fish;
}
