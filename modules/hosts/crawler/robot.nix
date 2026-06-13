# Robot I/O + camera for the quadruped. Enables the I2C/SPI/UART buses via the
# config.txt generator, defines + wires the hardware groups (gpio/i2c/spi are
# not standard NixOS groups, so we create them and add udev rules), and ships a
# python + vision env. No control service yet (YAGNI) — that lands as its own
# aspect later. camera_auto_detect is already mkDefault true in the board base
# module, so the CSI camera overlay loads without extra config here.
{ ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.crawler.nixos =
    { pkgs, ... }:
    {
      # config.txt: i2c_arm/spi are dtparams (dtparam=…=on); enable_uart is a
      # top-level option (enable_uart=1). Schema per nixos-raspberrypi
      # modules/configtxt.nix.
      hardware.raspberry-pi.config.all = {
        base-dt-params = {
          i2c_arm = {
            enable = true;
            value = "on";
          };
          spi = {
            enable = true;
            value = "on";
          };
        };
        options.enable_uart = {
          enable = true;
          value = 1;
        };
      };

      # gpio/i2c/spi are not created by default; define them so the membership
      # below is real, and grant device-node access via udev. (dialout + video
      # are standard NixOS groups.)
      users.groups = {
        gpio = { };
        i2c = { };
        spi = { };
      };
      users.users.${meta.username}.extraGroups = [
        "gpio"
        "i2c"
        "spi"
        "dialout"
        "video"
      ];
      services.udev.extraRules = ''
        SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
        SUBSYSTEM=="spidev", GROUP="spi", MODE="0660"
        SUBSYSTEM=="gpio", GROUP="gpio", MODE="0660"
        KERNEL=="gpiomem", GROUP="gpio", MODE="0660"
      '';

      environment.systemPackages = with pkgs; [
        # Camera / vision. opencv 5 is not packaged yet -> opencv4 (cv2, 4.12).
        # libcamera + ffmpeg here are the nixos-raspberrypi overlay-optimized
        # builds. picamera2 is unpackaged; capture via libcamera CLI / V4L2.
        libcamera
        v4l-utils
        i2c-tools # i2cdetect/i2cget for bringing up I2C peripherals
        ffmpeg
        (python3.withPackages (
          ps: with ps; [
            numpy
            opencv4
            pyserial
            smbus2
            gpiozero
          ]
        ))
      ];
    };
}
