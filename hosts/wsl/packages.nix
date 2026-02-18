{ pkgs, ... }:
{
  home.packages = with pkgs; [
    openssl
    openssl.dev
    wsl-open
  ];
}
