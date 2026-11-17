# Keep the existing Ed25519 identity; do not rotate keys or offer RSA identities.
{
  services.openssh = {
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings = {
      HostKeyAlgorithms = "ssh-ed25519";
      # SwiftNIO incorrectly requires MAC overlap even for AES-GCM, which has
      # its own authentication. Offer its compatibility MAC, but only with
      # AEAD ciphers so it cannot enable a weaker cipher/MAC combination.
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
        "hmac-sha2-256"
      ];
    };
  };
}
