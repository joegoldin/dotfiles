# common/default.nix
{
  lib,
  inputs,
  outputs,
  config,
  username,
  hostname,
  stateVersion,
  ...
}: {
  imports = [
    ./configuration.nix
  ];
}
