# I2S speaker for the SunFounder Robot HAT V4 — a declarative translation of
# SunFounder's imperative i2samp.sh. The V4 HAT exposes a PCM5102A-class I2S DAC
# driven by the mainline `hifiberry-dac` overlay (ALSA card `sndrpihifiberry`),
# with an onboard amplifier whose enable line is BCM GPIO20.
#
# i2samp.sh does three things; we do all three declaratively and skip its
# PulseAudio/raspi-config steps (robot_hat plays via pygame/SDL2 and aplay
# straight to ALSA, so PulseAudio is unnecessary):
#   1. add `dtoverlay=hifiberry-dac` to config.txt
#   2. write the softvol /etc/asound.conf stack (default device = "robothat")
#   3. assert the amp-enable GPIO high + play a short silence (anti-pop/overheat)
{ ... }:
{
  den.aspects.scarab.nixos =
    { pkgs, ... }:
    {
      # 1. Enable the I2S DAC overlay (this also turns on I2S). -> dtoverlay=hifiberry-dac
      hardware.raspberry-pi.config.all.dt-overlays.hifiberry-dac = {
        enable = true;
        params = { };
      };

      # 2. The softvol chain robot_hat expects, verbatim from i2samp.sh's
      # without-mic branch. `play`/`aplay`/pygame all hit `default` = robothat.
      environment.etc."asound.conf".text = ''
        pcm.speaker {
            type hw
            card sndrpihifiberry
        }

        pcm.dmixer {
            type dmix
            ipc_key 1024
            ipc_perm 0666
            slave {
                pcm "speaker"
                period_time 0
                period_size 1024
                buffer_size 8192
                rate 44100
                channels 2
            }
        }

        ctl.dmixer {
            type hw
            card sndrpihifiberry
        }

        pcm.softvol {
            type softvol
            slave.pcm "dmixer"
            control {
                name "robot-hat speaker Playback Volume"
                card sndrpihifiberry
            }
            min_dB -51.0
            max_dB 0.0
        }

        pcm.robothat {
            type plug
            slave.pcm "softvol"
        }

        ctl.robothat {
            type hw
            card sndrpihifiberry
        }

        pcm.!default robothat
        ctl.!default robothat
      '';

      # 3. Assert the Robot HAT V4 amplifier-enable line (BCM20) high at boot and
      # play 0.5s of silence to avoid the speaker pop/overheat SunFounder warns
      # about. robot_hat's enable_speaker() does the same on demand, but doing it
      # at boot means audio works headless without first constructing Music().
      systemd.services.robot-hat-speaker = {
        description = "Enable Robot HAT speaker amp (BCM20) + anti-pop silence";
        wantedBy = [ "multi-user.target" ];
        after = [ "sound.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # Best-effort, never fails activation. `pinctrl set 20 op dh` drives
          # BCM20 high (pinctrl is the modern RPi GPIO tool; raspi-gpio is
          # deprecated and errors on recent kernels). The I2S card only appears
          # after the hifiberry-dac overlay loads (post-reboot), so the anti-pop
          # tone is gated on it. robot_hat.enable_speaker() also asserts the pin
          # on demand, so a miss here is harmless.
          ExecStart = pkgs.writeShellScript "robot-hat-speaker-enable" ''
            ${pkgs.raspberrypi-utils}/bin/pinctrl set 20 op dh || true
            if ${pkgs.alsa-utils}/bin/aplay -l 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qi sndrpihifiberry; then
              ${pkgs.sox}/bin/play -q -n trim 0.0 0.5 >/dev/null 2>&1 || true
            fi
          '';
        };
      };
    };
}
