# nix eval --impure --json --expr 'let f = builtins.getFlake (toString ./.); in import ./modules/hosts/elphael/_unlock-tests.nix { inherit (f.inputs.nixpkgs) lib; config = f.nixosConfigurations.elphael.config; }'
{ lib, config }:
let
  initrd = config.boot.initrd;
  ssh = initrd.network.ssh;
  daemon = initrd.systemd.services.tailscaled-unlock;
  serve = initrd.systemd.services.tailscale-unlock-serve;
  sshConfig = initrd.systemd.contents."/etc/ssh/sshd_config".text;
in
lib.runTests {
  testSystemdInitrd = {
    expr = initrd.systemd.enable && initrd.network.enable;
    expected = true;
  };
  testLoopbackOnlySSH = {
    expr = lib.filter (lib.hasPrefix "ListenAddress ") (lib.splitString "\n" sshConfig);
    expected = [ "ListenAddress 127.0.0.1" ];
  };
  testSSHPort = {
    expr = ssh.port;
    expected = 222;
  };
  testKeyOnlySSH = {
    expr = ssh.authorizedKeys != [ ] && lib.hasInfix "PasswordAuthentication no" sshConfig;
    expected = true;
  };
  testDedicatedHostKey = {
    expr = ssh.hostKeys;
    expected = [ "/etc/secrets/initrd/elphael-unlock_ed25519_key" ];
  };
  testStateOutsideStore = {
    expr = initrd.secrets."/var/lib/tailscale/tailscaled.state";
    expected = "/etc/secrets/initrd/elphael-unlock.state";
  };
  testUserspaceTransport = {
    expr = lib.hasInfix "--tun=userspace-networking" daemon.serviceConfig.ExecStart;
    expected = true;
  };
  testTailnetNotFunnel = {
    expr =
      lib.hasInfix "serve --bg --yes --tcp=222 tcp://127.0.0.1:222" serve.script
      && !(lib.hasInfix "funnel" serve.script);
    expected = true;
  };
  testSeparateIdentity = {
    expr =
      lib.hasInfix "--hostname=elphael-unlock" serve.script && lib.hasInfix "--ssh=false" serve.script;
    expected = true;
  };
  testDedicatedUnlockTag = {
    expr = lib.hasInfix "--advertise-tags=tag:ssh-in-only" serve.script;
    expected = true;
  };
  testConsoleUnlockPreserved = {
    expr =
      !(builtins.elem "systemd-ask-password-console.service" initrd.systemd.suppressedUnits)
      && !(builtins.elem "systemd-ask-password-console.path" initrd.systemd.suppressedUnits);
    expected = true;
  };
  testNICAvailable = {
    expr =
      builtins.elem "igc" initrd.availableKernelModules
      && initrd.systemd.network.networks."10-unlock-wired".networkConfig.DHCP == "ipv4";
    expected = true;
  };
  testNormalTailscaleUnchanged = {
    expr = config.services.tailscale.enable && config.services.openssh.settings.PermitRootLogin == "no";
    expected = true;
  };
  testBootloaderSupportsSecrets = {
    expr = config.boot.lanzaboote.enable && config.boot.loader.supportsInitrdSecrets;
    expected = true;
  };
}
