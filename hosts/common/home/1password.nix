{
  dotfiles-secrets,
  ...
}:
let
  op = import "${dotfiles-secrets}/1password.nix";
in
{
  # 1Password SSH agent config — only offer the specified key
  xdg.configFile."1Password/ssh/agent.toml".text = ''
    [[ssh-keys]]
    item = "${op.sshKeyItem}"
    vault = "${op.sshKeyVault}"
  '';
}
