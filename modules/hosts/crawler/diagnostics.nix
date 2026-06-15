# Permanent on-console status board. tty1 (the attached HDMI display) shows a
# compact, self-refreshing health summary instead of a login prompt — handy for
# a headless robot you occasionally glance at. Login is still available: switch
# to another VT (Alt+F2) for a getty (set a console password once over ssh:
# `sudo passwd <user>`, persists since users.mutableUsers = true).
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
        while true; do
          # --- gather (each check collapses to one status line) ---
          if [ -e /run/agenix/crawler-wlan ]; then
            sec="[OK] present ($(stat -c '%sB %U %a' /run/agenix/crawler-wlan))"
          else
            sec="[!!] MISSING — agenix did not decrypt it"
          fi

          if dmesg 2>/dev/null | grep -qiE 'brcmfmac.*Firmware:'; then
            radio="[OK] brcmfmac firmware loaded"
          elif dmesg 2>/dev/null | grep -qi 'brcmfmac'; then
            radio="[??] brcmfmac present, no firmware line"
          else
            radio="[!!] brcmfmac not loaded"
          fi

          if [ -d /sys/class/net/wlan0 ]; then
            st=$(cat /sys/class/net/wlan0/operstate 2>/dev/null); [ -z "$st" ] && st="?"
            ip4=$(ip -4 -br addr show wlan0 2>/dev/null | awk '{print $3}'); [ -z "$ip4" ] && ip4="none"
            wlan="state=$st  ip=$ip4"
          else
            wlan="[!!] wlan0 absent"
          fi

          act=$(systemctl is-active wpa_supplicant.service 2>/dev/null); [ -z "$act" ] && act="unknown"
          link=$(iw dev wlan0 link 2>/dev/null)
          if printf '%s' "$link" | grep -qi 'Connected to'; then
            ssid=$(printf '%s' "$link" | sed -nE 's/.*SSID: (.*)/\1/p' | head -1)
            sig=$(printf '%s' "$link" | sed -nE 's/.*signal: (.*)/\1/p' | head -1)
            wpa="[OK] $act  SSID=$ssid  $sig"
          else
            wpa="[$act] not associated"
          fi

          gw=$(ip route show default 2>/dev/null | awk '{print $3; exit}'); [ -z "$gw" ] && gw="none"
          if [ "$gw" != "none" ] && ping -c1 -W1 "$gw" >/dev/null 2>&1; then
            net="[OK] gateway $gw reachable"
          elif ping -c1 -W1 1.1.1.1 >/dev/null 2>&1; then
            net="[OK] internet reachable (gw $gw)"
          else
            net="[--] no route (gw $gw)"
          fi

          tsip=$(tailscale ip -4 2>/dev/null | head -1)
          if [ -n "$tsip" ]; then ts="[OK] $tsip"; else ts="[--] $(tailscale status 2>&1 | head -1)"; fi

          # --- render ---
          printf '\033c'
          echo "==================== CRAWLER STATUS ===================="
          printf '  %-11s %s\n' "host/time"   "$(uname -n)  $(date '+%H:%M:%S')  (refresh 5s)"
          printf '  %-11s %s\n' "wifi-secret" "$sec"
          printf '  %-11s %s\n' "radio"       "$radio"
          printf '  %-11s %s\n' "wlan0"       "$wlan"
          printf '  %-11s %s\n' "wpa_supp"    "$wpa"
          printf '  %-11s %s\n' "network"     "$net"
          printf '  %-11s %s\n' "tailscale"   "$ts"
          case "$wpa" in
            "[OK]"*) : ;;
            *)
              err=$(journalctl -b --no-pager -n 40 -u 'wpa_supplicant*' 2>/dev/null \
                    | grep -iE 'fail|error|exception|denied|invalid|ctrl_iface' | tail -1)
              [ -n "$err" ] && printf '  %-11s %s\n' "last-err" "$err"
              ;;
          esac
          echo "========================================================"
          echo "  Alt+F2 for a login console (set one once via: sudo passwd)"
          sleep 5
        done
      '';
    in
    {
      # tty1 shows the status board instead of a login prompt. Other VTs keep
      # their on-demand gettys (Alt+F2 → login), so this is safe to leave on.
      systemd.services."getty@tty1".enable = false;
      systemd.services."autovt@tty1".enable = false;

      systemd.services.crawler-status = {
        description = "Crawler status board on the console (tty1)";
        wantedBy = [ "multi-user.target" ];
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
}
