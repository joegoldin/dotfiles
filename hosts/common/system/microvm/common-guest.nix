# Shared module imported by every `vm`-generated VM's module.nix.
#
# Receives via _module.args:
#   meta           — the VM's meta.json parsed into an attrset
#   cliSshPubKey   — public half of /var/lib/microvms/ssh/id_ed25519 (for `vm ssh`)
#   userSshPubKey  — the human's personal pubkey (for plain `ssh <name>.vm`)
#   fishGuest      — the fish-guest home-manager module (passed as an import target)
{
  lib,
  pkgs,
  meta,
  cliSshPubKey,
  userSshPubKey,
  fishGuest,
  ...
}:
{
  # ── Identity ──────────────────────────────────────────────────────────────
  networking.hostName = meta.name;
  networking.domain = "vm";

  # ── Networking (single DHCP iface on the host's vmbr0 bridge) ─────────────
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  # Nameserver is handed out by the host's dnsmasq via DHCP option 6.
  networking.firewall.enable = lib.mkDefault false;

  time.timeZone = lib.mkDefault "America/Los_Angeles";

  # ── Users ─────────────────────────────────────────────────────────────────
  # meta.user is always set by `vm new` (captured from the creator's $USER).
  users.users.${meta.user} = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    initialPassword = meta.user;
    openssh.authorizedKeys.keys =
      [ cliSshPubKey ] ++ lib.optional (userSshPubKey != null && userSshPubKey != "") userSshPubKey;
  };
  users.users.root = {
    openssh.authorizedKeys.keys = [ cliSshPubKey ];
    initialPassword = "root";
  };
  security.sudo.wheelNeedsPassword = false;

  # ── SSH daemon ────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # ── microvm guest options ─────────────────────────────────────────────────
  microvm = {
    hypervisor = meta.hypervisor or "qemu";
    mem = meta.ram_mb;
    vcpu = meta.cpu;
    # Use a writable overlay so runtime installs (nix-env, nix-shell) don't
    # require a rebuild.
    writableStoreOverlay = "/nix/.rw-store";

    interfaces = [
      {
        type = "tap";
        id = "vm-${meta.name}";
        mac = meta.mac;
      }
    ];

    shares =
      [
        # Nix store share — essential for starting up.
        {
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          tag = "ro-store";
          proto = "virtiofs";
        }
      ]
      ++ (map (m: {
        source = m.src;
        mountPoint = m.dst;
        tag = m.tag;
        proto = "virtiofs";
      }) (meta.mounts or [ ]));

    # Persistent root disk. microvm creates the qcow2 on first boot at the
    # service's WorkingDirectory (/var/lib/microvms/<name>/).
    volumes = [
      {
        image = "root.img";
        mountPoint = "/";
        size = meta.disk_gb * 1024;
        fsType = "ext4";
      }
    ];
  };

  # User-requested mounts get the `ro` option when marked read-only.
  fileSystems = lib.listToAttrs (
    map (m: {
      name = m.dst;
      value = {
        options = [ "defaults" ] ++ lib.optional (m.ro or false) "ro";
      };
    }) (meta.mounts or [ ])
  );

  # Enable system-level fish so `users.users.<user>.shell = pkgs.fish` is valid.
  programs.fish.enable = true;

  # ── home-manager for the guest user (fish-guest) ──────────────────────────
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${meta.user} = import fishGuest;
  };

  # ── Base packages always present in a guest ───────────────────────────────
  environment.systemPackages = with pkgs; [
    fish
    git
  ];

  system.stateVersion = lib.trivial.release;
}
