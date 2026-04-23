# Host-side infrastructure for the `vm` CLI (see docs/plans/2026-04-23-vm-command-design.md).
#
# - Enables microvm.nix host module (systemd template, state dir)
# - Host-only bridge vmbr0 at 10.100.0.1/24 (NetworkManager is told to leave it alone)
# - dnsmasq on vmbr0 for DHCP + *.vm DNS, driven by a lease file maintained by the `vm` CLI
# - NAT so VMs reach the internet via the host's uplink
# - Firewall: vmbr0 trusted (bidirectional host <-> VM ports)
# - polkit rule: vmusers can start/stop microvm@* systemd units without password
# - Activation: generates a CLI-owned SSH keypair used by `vm ssh`
{
  config,
  pkgs,
  inputs,
  username,
  ...
}:
let
  # Uplink interface on joe-desktop. Confirmed via `ip -o link show`.
  uplink = "enp8s0";
  # Host's address on the VM bridge.
  hostIp = "10.100.0.1";
in
{
  imports = [ inputs.microvm-nix.nixosModules.host ];

  # ── microvm.nix host module ───────────────────────────────────────────────
  microvm.host.enable = true;

  # ── Group for CLI users ───────────────────────────────────────────────────
  users.groups.vmusers = { };
  users.users.${username}.extraGroups = [ "vmusers" ];

  # ── Bridge ────────────────────────────────────────────────────────────────
  # Scripted-networking bridge (plays fine alongside NetworkManager when NM is
  # told to ignore this specific interface, below).
  networking.bridges.vmbr0.interfaces = [ ];
  networking.interfaces.vmbr0 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = hostIp;
        prefixLength = 24;
      }
    ];
  };

  # Keep NetworkManager's hands off vmbr0 so it doesn't fight scripted networking.
  # (NetworkManager is enabled globally on joe-desktop; we just carve out this one iface.)
  networking.networkmanager.unmanaged = [ "interface-name:vmbr0" ];

  # ── NAT for VM -> internet ────────────────────────────────────────────────
  networking.nat = {
    enable = true;
    internalInterfaces = [ "vmbr0" ];
    externalInterface = uplink;
  };

  # ── Firewall ──────────────────────────────────────────────────────────────
  # Trust the VM bridge fully — VMs can reach any host port, and vice versa
  # (the spec calls for bidirectional open access on the host-only bridge).
  networking.firewall.trustedInterfaces = [ "vmbr0" ];
  # Allow DHCP request responses on the bridge (dnsmasq).
  networking.firewall.interfaces.vmbr0 = {
    allowedUDPPorts = [
      53
      67
    ];
    allowedTCPPorts = [ 53 ];
  };

  # ── dnsmasq (DHCP + *.vm DNS) ─────────────────────────────────────────────
  # Leases are driven by /var/lib/microvms/dnsmasq.leases (managed by the `vm` CLI).
  # dnsmasq binds to vmbr0 only so it doesn't conflict with systemd-resolved.
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "vmbr0";
      bind-interfaces = true;
      listen-address = hostIp;
      port = 53;
      dhcp-range = "10.100.0.10,10.100.0.250,12h";
      domain = "vm";
      local = "/vm/";
      expand-hosts = true;
      dhcp-hostsfile = "/var/lib/microvms/dnsmasq.leases";
      # Serve authoritatively for the .vm domain — don't forward upstream.
      auth-server = "vm";
      # Don't read /etc/resolv.conf or /etc/hosts (avoid loops with resolved).
      no-resolv = true;
      no-hosts = true;
      # Upstream DNS for VMs (Cloudflare only).
      server = [
        "1.1.1.1"
        "1.0.0.1"
      ];
    };
  };

  # ── State directory bootstrap ─────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    # Group-writable root dir for CLI-owned per-VM subdirs. The microvm.nix
    # module also ensures /var/lib/microvms exists; this just tightens perms.
    "d /var/lib/microvms                     0775 microvm vmusers -"
    "d /var/lib/microvms/profiles            0755 root    vmusers -"
    "d /var/lib/microvms/profiles/custom     0775 root    vmusers -"
    "d /var/lib/microvms/ssh                 0755 root    vmusers -"
    "f /var/lib/microvms/dnsmasq.leases      0644 root    vmusers -"
    "f /var/lib/microvms/events.log          0664 root    vmusers -"
    "f /var/lib/microvms/state.json          0664 root    vmusers -"
  ];

  # ── polkit: vmusers can manage microvm@ systemd units ─────────────────────
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.isInGroup("vmusers")) {
        var unit = action.lookup("unit");
        if (unit && (unit.indexOf("microvm@") == 0 ||
                     unit.indexOf("microvm-") == 0)) {
          return polkit.Result.YES;
        }
      }
    });
  '';

  # ── CLI SSH keypair (baked into every VM as authorized_keys) ──────────────
  system.activationScripts.microvmCliSshKey = ''
    mkdir -p /var/lib/microvms/ssh
    if [ ! -f /var/lib/microvms/ssh/id_ed25519 ]; then
      ${pkgs.openssh}/bin/ssh-keygen \
        -t ed25519 -N "" \
        -f /var/lib/microvms/ssh/id_ed25519 \
        -C "vm-cli@${config.networking.hostName}"
    fi
    chown root:vmusers /var/lib/microvms/ssh/id_ed25519*
    chmod 0640 /var/lib/microvms/ssh/id_ed25519
    chmod 0644 /var/lib/microvms/ssh/id_ed25519.pub
  '';

  # ── Built-in profiles shipped from the repo ───────────────────────────────
  # The built-ins are copied read-only from the repo snapshot at activation;
  # user profiles under custom/ are preserved across switches.
  system.activationScripts.microvmBuiltinProfiles = ''
    mkdir -p /var/lib/microvms/profiles/custom
    install -m 0644 ${./microvm/profiles/desktop.json} /var/lib/microvms/profiles/desktop.json
    install -m 0644 ${./microvm/profiles/minimal.json} /var/lib/microvms/profiles/minimal.json
    chown -R root:vmusers /var/lib/microvms/profiles
    chmod 0775 /var/lib/microvms/profiles/custom
  '';

  # ── Packages needed by the `vm` CLI ───────────────────────────────────────
  # (The CLI scripts themselves are installed via home-manager; these are their
  # runtime dependencies that live on the host side.)
  environment.systemPackages =
    let
      # Wrap module-gen.py so it's on PATH as `vm-module-gen`. The script is
      # pulled into the system closure directly from the repo checkout.
      vmModuleGen = pkgs.writeShellScriptBin "vm-module-gen" ''
        exec ${pkgs.python3}/bin/python3 ${./microvm/module-gen.py} "$@"
      '';
    in
    with pkgs;
    [
      vmModuleGen
      virt-viewer # `vm gui` opens SPICE via remote-viewer
      socat # `vm console` attaches to the serial socket
      zstd # `vm export` bundles with tar+zstd
    ];
}
