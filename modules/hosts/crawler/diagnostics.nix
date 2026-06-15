# Permanent on-console dashboard for tty1 (the attached HDMI display): a fixed
# status header at the top + a live, scrolling system-log tail below it, instead
# of a login prompt. Login still works via another VT (Alt+F2 → getty; set a
# console password once over ssh, users.mutableUsers = true).
#
# Layout uses an ANSI scrolling region (DECSTBM): the header occupies the top
# HROWS lines (redrawn in place, never scrolled), and `journalctl -f` streams
# into the region below it so logs stack/scroll instead of being wiped on each
# refresh.
{ ... }:
{
  den.aspects.crawler.nixos =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      board = pkgs.writeShellScript "crawler-status" ''
        export PATH=${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.gawk # was missing before -> awk-based IP/gw parsing returned empty
            pkgs.iproute2
            pkgs.util-linux
            pkgs.gnugrep
            pkgs.gnused
            pkgs.iw
            pkgs.iputils
            config.systemd.package
            pkgs.tailscale
          ]
        }
        HROWS=10
        SCROLL_TOP=$((HROWS + 1))

        # Console size from the controlling tty; sensible fallback.
        sz=$(stty size 2>/dev/null)
        ROWS=$(printf '%s' "$sz" | awk '{print $1}'); [ -z "$ROWS" ] && ROWS=40
        COLS=$(printf '%s' "$sz" | awk '{print $2}'); [ -z "$COLS" ] && COLS=100

        # Reset, then confine scrolling to below the header and park the cursor there.
        printf '\033c'
        printf '\033[%d;%dr' "$SCROLL_TOP" "$ROWS"
        printf '\033[%d;1H' "$SCROLL_TOP"

        # Stream logs into the scroll region (inherits this tty as stdout).
        journalctl -fb -o short --no-hostname -n "$((ROWS - SCROLL_TOP))" 2>&1 &
        LOG_PID=$!
        cleanup() { kill "$LOG_PID" 2>/dev/null; printf '\033[r\0338\033c'; }
        trap cleanup EXIT INT TERM

        hdr() { printf '\033[%d;1H\033[K%s' "$1" "$2"; }
        kv() { printf '\033[%d;1H\033[K  %-11s %s' "$1" "$2" "$3"; }

        render() {
          # --- gather (each check -> one line) ---
          if [ -e /run/agenix/crawler-wlan ]; then
            sec="[OK] present ($(stat -c '%sB %U %a' /run/agenix/crawler-wlan))"
          else
            sec="[!!] MISSING — agenix did not decrypt it"
          fi

          if dmesg 2>/dev/null | grep -qiE 'brcmfmac.*Firmware:'; then
            radio="[OK] brcmfmac firmware loaded"
          elif dmesg 2>/dev/null | grep -qi brcmfmac; then
            radio="[??] brcmfmac present, no firmware line"
          else
            radio="[!!] brcmfmac not loaded"
          fi

          # Egress dev/gw/src via the routing decision (robust to iface naming).
          route=$(ip route get 1.1.1.1 2>/dev/null | head -1)
          dev=$(printf '%s' "$route" | grep -oE 'dev [^ ]+' | awk '{print $2}')
          gw=$(printf '%s' "$route" | grep -oE 'via [0-9.]+' | awk '{print $2}')
          src=$(printf '%s' "$route" | grep -oE 'src [0-9.]+' | awk '{print $2}')
          wif="$dev"; [ -z "$wif" ] && wif=wlan0

          if [ -d "/sys/class/net/$wif" ]; then
            st=$(cat "/sys/class/net/$wif/operstate" 2>/dev/null); [ -z "$st" ] && st="?"
            ip4=$(ip -4 -br addr show "$wif" 2>/dev/null | awk '{print $3}')
            [ -z "$ip4" ] && ip4="$src"; [ -z "$ip4" ] && ip4="none"
            wlan="$wif  state=$st  ip=$ip4"
          else
            wlan="[!!] no wireless interface"
          fi

          act=$(systemctl is-active wpa_supplicant.service 2>/dev/null); [ -z "$act" ] && act=unknown
          link=$(iw dev "$wif" link 2>/dev/null)
          if printf '%s' "$link" | grep -qi 'Connected to'; then
            ssid=$(printf '%s' "$link" | sed -nE 's/.*SSID: (.*)/\1/p' | head -1)
            sig=$(printf '%s' "$link" | sed -nE 's/.*signal: (.*)/\1/p' | head -1)
            wpa="[OK] $act  SSID=$ssid  $sig"
          else
            wpa="[$act] not associated"
          fi

          if [ -n "$src" ] && ping -c1 -W1 1.1.1.1 >/dev/null 2>&1; then
            net="[OK] online — $dev src $src via $gw"
          elif [ -n "$src" ]; then
            net="[~~] route ok (gw $gw) but no ping reply"
          else
            net="[--] no default route"
          fi

          tsip=$(tailscale ip -4 2>/dev/null | head -1)
          if [ -n "$tsip" ]; then ts="[OK] $tsip"; else ts="[--] $(tailscale status 2>&1 | head -1)"; fi

          err="-"
          case "$wpa" in
            "[OK]"*) : ;;
            *)
              e=$(journalctl -b --no-pager -n 40 -u 'wpa_supplicant*' 2>/dev/null \
                  | grep -iE 'fail|error|denied|ctrl_iface' | tail -1)
              [ -n "$e" ] && err="$e"
              ;;
          esac

          # --- render header in place (save/restore the log stream's cursor) ---
          printf '\0337'
          hdr 1 "==================== CRAWLER STATUS ===================="
          kv  2 "host/time"   "$(uname -n)  $(date '+%H:%M:%S')  (refresh 5s, Alt+F2=login)"
          kv  3 "wifi-secret" "$sec"
          kv  4 "radio"       "$radio"
          kv  5 "wlan"        "$wlan"
          kv  6 "wpa_supp"    "$wpa"
          kv  7 "network"     "$net"
          kv  8 "tailscale"   "$ts"
          kv  9 "last-err"    "$err"
          hdr 10 "======================= live logs ====================="
          printf '\0338'
        }

        render
        while true; do
          render
          sleep 5
        done
      '';
    in
    {
      systemd.services = {
        # tty1 = dashboard, not a login prompt. Other VTs keep on-demand gettys.
        "getty@tty1".enable = false;
        "autovt@tty1".enable = false;

        crawler-status = {
          description = "Crawler status board + live logs on the console (tty1)";
          wantedBy = [ "multi-user.target" ];
          environment.TERM = "linux";
          serviceConfig = {
            ExecStart = board;
            StandardInput = "tty";
            StandardOutput = "tty";
            TTYPath = "/dev/tty1";
            TTYReset = true;
            TTYVHangup = true;
            Restart = "always";
            RestartSec = 2;
          };
        };
      };
    };
}
