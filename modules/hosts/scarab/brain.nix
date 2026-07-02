# The on-device AI brain for the quadruped: the crawler flake's NixOS module
# (services.crawler-brain) running robotd (the MCP body, Navigator-driven) + the
# pi agent (umans provider) in a tmux session, so the robot is fully autonomous
# off the desktop — AND the control center can take over the body over the LAN
# via `crawler.local` (robotd binds 0.0.0.0 by default).
#
# A den.aspects.scarab.nixos fragment, merged by name with the other split
# files (system.nix / net.nix / robot.nix). The umans key comes from the agenix
# raw-key secret declared in default.nix (age.secrets.umans_api_key); the module
# exports it as UMANS_API_KEY=$(cat <apiKeyFile>) for both robotd + the brain.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.scarab.nixos =
    { config, pkgs, ... }:
    {
      imports = [ inputs.crawler.nixosModules.default ];

      # `crawler-attach`: jump into the running brain's tmux session (the pi
      # agent). Matches the module's default tmuxSession name ("crawler-brain").
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "crawler-attach" ''
          exec ${pkgs.tmux}/bin/tmux attach -t crawler-brain
        '')
      ];

      services.crawler-brain = {
        enable = true;
        backend = "real"; # drive the Robot-HAT servos + BerryIMU
        user = meta.username; # an account in the i2c/spi/gpio/audio groups (see robot.nix)
        controller = "navigator"; # robotd drives the Navigator deploy loop

        # The agenix raw-key secret (just the umans key, not KEY=value); the
        # module reads it at runtime into UMANS_API_KEY for the pi agent + robotd.
        apiKeyFile = config.age.secrets.umans_api_key.path;

        # robot_hat / picrawler aren't in nixpkgs — inject the SunFounder overlay
        # packages this host already provides (the SAME attrs robot.nix uses),
        # plus opencv4 (cv2) so the on-device camera path is importable.
        # robot-hat propagates gpiozero/smbus2/spidev/pyserial/pyaudio/pygame, but
        # NOT the gpiozero pin-factory backends — add lgpio (the GPIOZERO_PIN_FACTORY
        # the host sets) + rpi-gpio so Pin/Ultrasonic/LED work (else: "No module
        # named 'lgpio'" on every ultrasonic read).
        extraPythonPackages =
          ps: with ps; [
            robot-hat
            picrawler
            opencv4
            lgpio
            rpi-gpio
          ];
      };
    };
}
