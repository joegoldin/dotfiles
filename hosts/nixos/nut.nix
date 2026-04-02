{
  config,
  ...
}:
let
  upsName = "cyberpower";
  upsmonPasswordFile = config.age.secrets.nut-upsmon-password.path;
in
{
  age.secrets.nut-upsmon-password = {
    file = ../../secrets/nut-upsmon-password.age;
    mode = "0400";
  };

  power.ups = {
    enable = true;
    mode = "standalone";

    ups.${upsName} = {
      driver = "usbhid-ups";
      port = "auto";
      description = "CyberPower CP1500PFCLCD";
    };

    users.upsmon = {
      passwordFile = upsmonPasswordFile;
      upsmon = "primary";
    };

    upsmon.monitor.${upsName} = {
      system = "${upsName}@localhost";
      powerValue = 1;
      user = "upsmon";
      passwordFile = upsmonPasswordFile;
      type = "primary";
    };
  };

  # Allow NUT to access the CyberPower USB device
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0764", ATTR{idProduct}=="0601", MODE="0664", GROUP="nut"
  '';
}
