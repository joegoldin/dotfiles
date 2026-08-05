# Bedroom LED signs (HomeKit, via Home Assistant): save their state and switch
# them off while the Elgato Facecam is in use, then put them back. Follows the
# same camera node as ./litra.nix, so the signs go dark as the Litras come up.
# HA's address and token both come from the private dotfiles-secrets input.
{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.elphael.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domains = import "${dotfiles-secrets}/domains.nix";
      facecam = import ./_facecam.nix { inherit lib pkgs; };

      # Duck is deliberately absent: it stays under manual control.
      signs = [
        "light.bedroom_desert_led_sign"
        "light.bedroom_moon_girl_led_sign"
        "light.bedroom_mushroom_girl_led_sign"
      ];

      # litra-autotoggle's `delay`, so both settle on the same events at the
      # same moment.
      settleSeconds = "1.5";

      # Snapshot -> one `<service>\t<payload>` line per entity. A light's colour
      # lives under whichever key its `color_mode` names, so the mode picks the
      # key rather than guessing. All three signs are brightness-only today.
      restoreProgram = ''
        def color_args(a):
          if   a.color_mode == "hs"         and a.hs_color          then { hs_color: a.hs_color }
          elif a.color_mode == "rgb"        and a.rgb_color         then { rgb_color: a.rgb_color }
          elif a.color_mode == "rgbw"       and a.rgbw_color        then { rgbw_color: a.rgbw_color }
          elif a.color_mode == "rgbww"      and a.rgbww_color       then { rgbww_color: a.rgbww_color }
          elif a.color_mode == "xy"         and a.xy_color          then { xy_color: a.xy_color }
          elif a.color_mode == "color_temp" and a.color_temp_kelvin then { color_temp_kelvin: a.color_temp_kelvin }
          else {} end;

        .[]
        # "unavailable"/"unknown" mean HA had no reading; leave those alone.
        | select(.state == "on" or .state == "off")
        # $off is the signs still switched off at restore time. One that is on
        # was changed by hand during the call, so it is no longer ours to move.
        | select(.entity_id as $e | $off | index($e) != null)
        | if .state == "off" then
            { service: "light/turn_off", data: { entity_id: .entity_id } }
          else
            { service: "light/turn_on",
              data: ({ entity_id: .entity_id }
                     # ceil, not round: these report brightness as pct x 2.55
                     # and HA floors on the way back in (measured), so
                     # anything lower loses a percent per camera cycle.
                     + (if .attributes.brightness then { brightness: (.attributes.brightness | ceil) } else {} end)
                     + (if (.attributes.effect // "None") != "None" then { effect: .attributes.effect } else {} end)
                     + color_args(.attributes)) }
          end
        | "\(.service)\t\(.data | tojson)"
      '';

      led-signs-autotoggle = pkgs.writeShellApplication {
        name = "led-signs-autotoggle";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          inotify-tools
          jq
        ];
        # No errexit: a failed HTTP call is something to log and carry on from.
        bashOptions = [
          "nounset"
          "pipefail"
        ];
        text = ''
          ha_url=${lib.escapeShellArg domains.homeassistantBaseUrl}
          facecam=${lib.escapeShellArg facecam.path}
          settle=${settleSeconds}
          snapshot="$STATE_DIRECTORY/snapshot.json"
          token=$(cat "$CREDENTIALS_DIRECTORY/ha-token")
          signs=(${lib.concatStringsSep " " (map lib.escapeShellArg signs)})

          # Token goes in via a curl config file on stdin, not argv:
          # /proc/<pid>/cmdline is world-readable. The retries are not
          # decorative: these HomeKit signs intermittently 500 on a service
          # call, and 5xx is one of the statuses curl treats as transient.
          ha_curl() {
            printf 'header = "Authorization: Bearer %s"\n' "$token" \
              | curl --silent --show-error --fail-with-body --max-time 20 \
                --retry 2 --retry-delay 1 --config - "$@"
          }

          ha_service() {
            local out
            if ! out=$(ha_curl --header "Content-Type: application/json" \
              --data "$2" "$ha_url/api/services/$1"); then
              echo "error: $1 failed: $out" >&2
              return 1
            fi
          }

          take_snapshot() {
            local entity body responses=""
            for entity in "''${signs[@]}"; do
              if ! body=$(ha_curl "$ha_url/api/states/$entity"); then
                echo "error: could not read $entity from Home Assistant" >&2
                return 1
              fi
              responses+="$body"$'\n'
            done
            # Via .new, so a failed write can't leave a half-parsed snapshot.
            if ! jq -s . <<< "$responses" > "$snapshot.new"; then
              rm -f "$snapshot.new"
              return 1
            fi
            mv "$snapshot.new" "$snapshot"
          }

          restore_snapshot() {
            local service payload rc=0 entity body states="" off_ids touched
            if [ ! -f "$snapshot" ]; then
              echo "error: $snapshot is missing, cannot restore the signs" >&2
              return 1
            fi

            # We left every sign off, so one that is on now was switched on by
            # hand during the call. Putting it back would overwrite a
            # deliberate choice, so restore only the ones still off. A sign we
            # cannot re-read is left alone too.
            for entity in "''${signs[@]}"; do
              if ! body=$(ha_curl "$ha_url/api/states/$entity"); then
                echo "error: could not re-read $entity; leaving it alone" >&2
                rc=1
                continue
              fi
              states+="$body"$'\n'
            done
            off_ids=$(jq -sc '[ .[] | select(.state == "off") | .entity_id ]' <<< "$states")
            touched=$(jq -sr '[ .[] | select(.state != "off") | .entity_id ] | join(", ")' <<< "$states")
            [ -n "$touched" ] && echo "changed by hand during the call, leaving alone: $touched"

            # shellcheck disable=SC2016  # $off is jq's, not the shell's
            while IFS=$'\t' read -r service payload; do
              ha_service "$service" "$payload" || rc=1
            done < <(jq -r --argjson off "$off_ids" \
              ${lib.escapeShellArg restoreProgram} "$snapshot")
            return "$rc"
          }

          signs_off() {
            # shellcheck disable=SC2016  # $ARGS is jq's, not the shell's
            ha_service light/turn_off \
              "$(jq -cn --args '{ entity_id: $ARGS.positional }' "''${signs[@]}")"
          }

          opens=0
          # Set only while *this* process is the reason the signs are off. A
          # close whose open we never saw — crash and restart mid-call — must
          # not turn anything on, so restore is gated on this, not the count.
          suppressed=0

          apply_state() {
            if [ "$opens" -gt 0 ]; then
              [ "$suppressed" -eq 1 ] && return 0
              echo "camera in use: saving the signs' state and switching them off"
              if ! take_snapshot; then
                echo "warning: no snapshot taken, leaving the signs alone" >&2
                return 0
              fi
              # Armed before the call, not after: a service call covering
              # several entities is not atomic, so a failure can still have
              # switched some of them off. Restoring lights that never moved is
              # harmless; stranding them off is not.
              suppressed=1
              if ! signs_off; then
                echo "warning: switching the signs off failed; will still restore" >&2
              fi
            else
              [ "$suppressed" -eq 0 ] && return 0
              echo "camera released: restoring the signs"
              if restore_snapshot; then
                suppressed=0
              else
                # Hold the flag, or the next call overwrites the last good
                # snapshot with the "off" we just failed to undo.
                echo "error: restore failed; keeping the snapshot to retry" >&2
              fi
            fi
          }

          # litra-autotoggle's algorithm: count outstanding opens, act once the
          # count holds still for $settle. Apps open and close the node several
          # times while a call starts.
          watch_camera() {
            local dev event pending=0 rc

            dev=$(readlink -f "$facecam" 2> /dev/null || true)
            if [ -z "$dev" ] || [ ! -e "$dev" ]; then
              # udev restarts this unit when the camera turns up.
              echo "$facecam is absent; nothing to watch"
              return 0
            fi
            echo "watching $dev"

            # inotify only names entries *inside* a watched directory, so watch
            # the parent. Filtering has to happen in inotifywait, not here:
            # /dev as a whole carries a few hundred tty/urandom events a
            # second, which would both burn CPU and mean the $settle read below
            # never times out. --include matches the full path.
            while :; do
              rc=0
              if [ "$pending" -eq 1 ]; then
                read -r -t "$settle" event || rc=$?
              else
                read -r event || rc=$?
              fi

              if [ "$rc" -eq 0 ]; then
                # inotifywait comma-joins names: a close arrives as
                # "CLOSE_NOWRITE,CLOSE", never bare.
                case ",$event," in
                  *,OPEN,*)
                    opens=$((opens + 1))
                    pending=1
                    ;;
                  *,CLOSE_WRITE,* | *,CLOSE_NOWRITE,*)
                    if [ "$opens" -gt 0 ]; then opens=$((opens - 1)); fi
                    pending=1
                    ;;
                esac
              elif [ "$rc" -gt 128 ]; then
                pending=0
                apply_state
              else
                echo "error: inotifywait on $dev exited" >&2
                return 1
              fi
            done < <(inotifywait --monitor --quiet --event open,close \
              --include "^$dev\$" --format '%e' "$(dirname "$dev")")
          }

          # Record the current state and touch nothing: a crash or restart must
          # never move a light by itself.
          if take_snapshot; then
            echo "startup: recorded the signs' current state"
          else
            echo "warning: could not reach Home Assistant at startup" >&2
          fi

          watch_camera
        '';
      };
    in
    {
      services.udev.packages = [ (facecam.restartOnReplug "led-signs-autotoggle.service") ];

      systemd.services.led-signs-autotoggle = {
        description = "Switch the bedroom LED signs off while the Elgato Facecam is in use";
        wantedBy = [ "multi-user.target" ];
        after = [
          "agenix.service"
          "network-online.target"
          "systemd-udevd.service"
          "tailscaled.service"
        ];
        wants = [
          "agenix.service"
          "network-online.target"
        ];

        serviceConfig = {
          Type = "simple";

          ExecStartPre = facecam.waitForDevice;
          ExecStart = lib.getExe led-signs-autotoggle;
          # If the camera never turns up the script exits 0 and the unit goes
          # idle; the udev rule above starts it again on plug. Real failures
          # (inotifywait dying) exit non-zero and do get restarted.
          Restart = "on-failure";
          RestartSec = 5;

          # Read by PID 1 as root, so the DynamicUser never touches /run/agenix.
          LoadCredential = [
            "ha-token:${config.age.secrets.homeassistant_api_key.path}"
          ];

          DynamicUser = true;
          StateDirectory = "led-signs-autotoggle";

          # Needs the network, so no PrivateNetwork. AF_NETLINK is not optional:
          # glibc's resolver enumerates interfaces before it resolves anything.
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
            "AF_UNIX"
          ];

          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" ];

          LogRateLimitIntervalSec = 30;
          LogRateLimitBurst = 100;
        };
      };
    };
}
