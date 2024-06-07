{
  username,
  ...
}:
{
  nixos-wsl.nixosModules.default
  {
    system.stateVersion = "24.05";
    wsl.enable = true;
    wsl.defaultUser = username;
  }
}
