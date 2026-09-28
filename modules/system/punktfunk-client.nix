# Native client for punktfunk (git.unom.io/unom/punktfunk), the game-streaming
# host running on the gaming PC. The upstream module's client half installs the
# GTK client and raises the UDP receive-buffer ceiling; openFirewall opens mDNS
# so hosts on the LAN are discovered without typing an address.
{ inputs, ... }:
{
  den.aspects.punktfunk-client.nixos = {
    imports = [ inputs.punktfunk.nixosModules.default ];

    services.punktfunk.client = {
      enable = true;
      openFirewall = true;
    };

    # CI publishes only punktfunk's own store paths here; without it the client
    # compiles the whole Rust workspace from source.
    nix.settings = {
      extra-substituters = [ "https://nix.unom.io" ];
      extra-trusted-public-keys = [
        "punktfunk-cache-1:yhOJmHxzg6tzXpxSFzlYn6Pc6r0jHprsWqt8MZC654o="
      ];
    };
  };
}
