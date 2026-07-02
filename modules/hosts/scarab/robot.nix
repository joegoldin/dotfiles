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
  den.aspects.scarab.nixos =
    { pkgs, ... }:
    {
      # config.txt: i2c_arm/spi are dtparams (dtparam=…=on). Schema per
      # nixos-raspberrypi modules/configtxt.nix. UART is already enabled by the
      # board base module (raspberrypi.nix sets enable_uart=true), so we don't
      # redefine it here — doing so collides on that scalar option.
      hardware.raspberry-pi.config.all.base-dt-params = {
        i2c_arm = {
          enable = true;
          value = "on";
        };
        spi = {
          enable = true;
          value = "on";
        };
      };

      # dtparam=i2c_arm=on brings up the I2C *controller*, but the userspace
      # /dev/i2c-1 char device only appears once the `i2c-dev` module is loaded
      # (Raspberry Pi OS does this via raspi-config; NixOS does not auto-load it).
      # Without it i2cdetect -y 1 fails ("No such file or directory") and the
      # Robot HAT (0x14) + BerryIMU (0x6a/0x1c) are unreachable -> RealBackend
      # can't open the bus. (Requires a reboot for the config.txt dtparam to take.)
      boot.kernelModules = [ "i2c-dev" ];

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

      # gpiozero talks to the kernel via lgpio on modern Pis; pin it so it
      # doesn't fall back to a missing RPi.GPIO backend.
      environment.variables.GPIOZERO_PIN_FACTORY = "lgpio";

      environment.systemPackages = with pkgs; [
        # Camera / vision. opencv 5 is not packaged yet -> opencv4 (cv2, 4.12).
        # libcamera + ffmpeg here are the nixos-raspberrypi overlay-optimized
        # builds. picamera2 is unpackaged; capture via libcamera CLI / V4L2.
        libcamera
        v4l-utils
        i2c-tools # i2cdetect/i2cget for bringing up I2C peripherals
        ffmpeg

        # Runtime CLI tools robot_hat shells out to (NOT python deps):
        sox # play/rec — speaker enable anti-pop + tone playback
        alsa-utils # aplay/amixer/speaker-test
        espeak-ng # TTS engine
        picotts # pico2wave — robot_hat's default TTS engine (was svox)
        raspberrypi-utils # pinctrl (speaker-enable pin; modern raspi-gpio replacement)
        libraspberrypi # vcgencmd (temp/throttle), raspistill legacy
        libgpiod # gpioset/gpiodetect for manual GPIO poking

        (python3.withPackages (
          ps: with ps; [
            # vision
            numpy
            opencv4
            pillow
            # SunFounder robotics stack
            robot-hat
            picrawler
            sunfounder-controller
            # hardware I/O (+ gpiozero backends)
            gpiozero
            lgpio
            rpi-gpio
            smbus2
            spidev
            pyserial
            pyaudio
            pygame
            # web / control / utilities common in these robot projects
            flask
            requests
            websockets
            readchar
            imutils
            pyzbar
          ]
        ))
      ];
    };
}
