{ pkgs }:
pkgs.testers.runNixOSTest {
  name = "dbus-broker-quotas";
  nodes.machine = {
    services.dbus = {
      enable = true;
      implementation = "broker";
      brokerPackage = pkgs.dbus-broker;
    };
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("dbus.service")
    machine.succeed("${pkgs.python3.interpreter} ${./dbus-broker-quota-test.py} ${pkgs.dbus-broker}/bin/dbus-broker-launch ${pkgs.systemd}/bin/systemd-socket-activate ${pkgs.systemd}/bin/busctl")
  '';
}
