# Keep the existing Ed25519 identity; do not rotate keys or offer RSA identities.
{
  services.openssh = {
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings.HostKeyAlgorithms = "ssh-ed25519";
  };
}
