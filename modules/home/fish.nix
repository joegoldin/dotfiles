# fish + atuin + fish-ai. Migration pattern B (pointed-at, with args shim):
# the legacy module tree is reused in place; it expects the
# `dotfiles-secrets` specialArg, which den does not provide, so we supply it
# via _module.args. Pattern A this once nothing else imports
# hosts/common/home/fish.
{ inputs, ... }:
{
  den.aspects.fish.homeManager = {
    imports = [ ../../hosts/common/home/fish ];
    _module.args.dotfiles-secrets = inputs.dotfiles-secrets;
  };
}
