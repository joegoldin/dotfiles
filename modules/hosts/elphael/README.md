# Elphael pre-boot unlock over Tailscale

The initrd joins the tailnet as **elphael-unlock**, separate from the running
system's **elphael** node. Connect from a tailnet device with Joe's SSH key:

```fish
ssh -p 222 root@elphael-unlock
# At the remote prompt:
unlock
```

Enter the LUKS passphrase. Boot completes and the SSH session disconnects. The
unlock identity goes offline; use the normal `elphael` connection after boot.
This is ordinary key-authenticated SSH, not Tailscale SSH. Tailnet policy must
allow your client to reach `elphael-unlock` on TCP 222.

## Tailnet policy prerequisite

The policy is managed in the private `dotfiles-secrets` repository at
`tailscale/policy.hujson`, with setup and deployment steps in its
`tailscale/README.md`. Before enrollment, validate and deploy that policy through
its GitHub Actions workflow. The enrollment helper requests `tag:ssh-in-only`.
Full-access clients can reach this node on every port/protocol; the initrd
itself listens only on TCP 222. Untagged clients have no outgoing permission,
and this server role has no grants to initiate tailnet connections. Return
traffic for incoming SSH is automatically allowed.

Keep initiating clients tagged `full-access`. Existing `ssh-in-only` machines,
including this unlock identity, keep their tags and credentials; do not
reauthenticate them for the role cleanup. Untagged servers are also inbound-only
by default, so new general servers need no extra role just for isolation.
**Never give the unlock node `full-access`**: additive permissions would defeat
its outbound isolation.

Permissions are additive: broad rules with `*` as source (or another selector
that includes isolated nodes) must be narrowed too. Review both `grants` and legacy
`acls`, and preserve existing access for your normal devices and servers. Do
not replace the entire policy with a generic example. Add policy tests for the
allowed incoming connection and denied outgoing connections to your actual
servers, and verify that they pass before saving.

This dotfiles repository does **not** apply or verify the live policy; the
private repo's workflow does that. Isolation comes from the absence of outgoing
grants, not from the tag itself.
The helper asks you to confirm that policy has been applied before registering
anything. Tailnet policy does not prohibit
ordinary LAN/internet traffic; Tailscale still needs outbound coordination and
relay connectivity.

## One-time enrollment (on Elphael)

After the policy is configured, build the enrollment helper without activating
a system or rebooting:

```fish
nix build .#nixosConfigurations.elphael.config.system.build.elphaelUnlockEnroll --out-link /tmp/elphael-unlock-enroll
sudo /tmp/elphael-unlock-enroll/bin/elphael-unlock-enroll
```

Follow the printed Tailscale login URL. This registers a new, persistent node;
it does not log out or modify the running system's Tailscale node. It also
generates a dedicated SSH host key. Re-running the helper reuses both identities.
No reusable auth key is needed.

In the Tailscale admin console:

- Approve `elphael-unlock` if device approval is enabled.
- **Disable key expiry** for this node so remote unlock does not expire while
  the machine is offline.
- Confirm that the node has `tag:ssh-in-only` and that the restrictive policy
  above applies. Do not use the node until its policy tests and deployment pass.

Then install the new boot generation:

```fish
just boot
```

Enrollment must precede bootloader installation: the bootloader needs
`/etc/secrets/initrd/elphael-unlock.state` and
`/etc/secrets/initrd/elphael-unlock_ed25519_key` locally. They are copied into the
boot image by Lanzaboote, not evaluated or copied into the Nix store.

Reboot only when you have physical console access for the first test. From a
second tailnet device, check `ssh -p 222 root@elphael-unlock`, run `unlock`, and
confirm that the normal system boots. On a subsequent boot, test entering the
passphrase directly with the attached keyboard and monitor without SSH. Also
check that connecting to Elphael's LAN address on port 222 fails. Console
passphrase entry remains available even
when the network, DNS, Tailscale, or enrollment fails.

## Transport and security

- Only the wired Intel I226-V interface (MAC `04:7c:16:76:d0:3c`, currently
  `enp8s0`) gets initrd DHCP. Wi-Fi and the desktop's NetworkManager profiles are
  not used. Initrd systemd-resolved uses the DNS servers supplied by DHCP.
- Initrd sshd listens only on `127.0.0.1:222`. A userspace Tailscale daemon uses
  **Serve**, not Funnel, to forward tailnet TCP 222 to that listener. There is
  no public or LAN SSH listener, and no router port-forward is needed.
- Only Joe's configured SSH public key is authorized. Password SSH login and
  SSH forwarding are disabled. The disk passphrase is still required; it is
  never stored in the boot image.
- The initrd has a dedicated node state and host key. Neither the running
  system's Tailscale state nor its SSH host key is copied.
- **The pre-boot credentials are necessarily present on the unencrypted boot
  partition.** Secure Boot authenticates the image; it does not encrypt it.
  Someone who reads that partition can steal this tailnet identity and SSH
  host key, though they still need the LUKS passphrase to decrypt root. Narrow
  tailnet permissions limit the damage. Do not treat this identity as a trusted
  client with broad access to other machines.
- Initrd state changes are ephemeral. After re-enrolling or rotating the
  dedicated identity/key, run `just boot` again to refresh the boot image.
  Revoking the node in Tailscale disables remote unlock; console unlock remains
  available. Old boot generations may contain old credentials.

Configuration: `modules/hosts/elphael/unlock.nix`.
