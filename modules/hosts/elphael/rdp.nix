# RDP server for elphael: KDE's krdpserver shares the *live* Plasma session
# (same screens, same open windows) rather than spawning a second desktop, so
# `remmina` on another machine picks up exactly where the physical seat left off.
#
# Reachability is deliberately narrow: port 3389 is opened only on tailscale0,
# so the tailnet can reach it while the LAN and the internet cannot. Nothing
# here touches networking.firewall.allowedTCPPorts (which is global).
#
# krdpserver has no --password-file, so the password is passed as an argv and is
# visible in `ps` to anyone with a shell on elphael. That is fine for a
# single-user workstation; the alternative is dropping the -u/-p flags and
# letting krdpserver pull credentials from KWallet, which then has to be set up
# by hand in System Settings -> Remote Desktop on every rebuild of the profile.
{ ... }:
let
  meta = import ../../_lib/meta.nix;
  username = meta.username;
  stateDir = "/home/${username}/.local/share/krdpserver";
in
{
  den.aspects.elphael.nixos =
    { pkgs, ... }:
    {
      # Tailnet-only. `networking.firewall.interfaces.<iface>` adds the port to
      # that interface's chain alone, unlike the top-level allowedTCPPorts.
      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 3389 ];

      # kcm_krdpserver puts a "Remote Desktop" page in System Settings, which is
      # the sane place to check state / flip the monitor being shared.
      environment.systemPackages = [ pkgs.kdePackages.krdp ];
    };

  den.aspects.elphael.homeManager =
    { pkgs, lib, ... }:
    let
      # Without --certificate krdpserver mints a throwaway cert per start, so
      # every reconnect shows remmina a new fingerprint. Generate one long-lived
      # self-signed pair instead and reuse it.
      krdpStart = pkgs.writeShellApplication {
        name = "krdp-server-start";
        runtimeInputs = with pkgs; [
          openssl
          flatpak
          coreutils
        ];
        text = ''
          dir="${stateDir}"
          mkdir -p "$dir"
          chmod 700 "$dir"

          if [ ! -s "$dir/krdp.crt" ] || [ ! -s "$dir/krdp.key" ]; then
            echo "krdp: generating self-signed certificate in $dir"
            openssl req -x509 -newkey rsa:4096 -nodes -days 3650 \
              -keyout "$dir/krdp.key" -out "$dir/krdp.crt" \
              -subj "/CN=elphael"
            chmod 600 "$dir/krdp.key"
          fi

          # First run mints a password so the unit never fails closed. Read it
          # with `krdp-password`; overwrite the file to choose your own.
          if [ ! -s "$dir/password" ]; then
            openssl rand -base64 18 | tr -d '\n' > "$dir/password"
            echo "krdp: generated a new RDP password at $dir/password"
          fi
          chmod 600 "$dir/password"

          # Pre-authorize the remote-desktop portal for krdpserver so the first
          # connection doesn't block on a KDE permission dialog nobody is at the
          # keyboard to accept. Same call malenia makes; best-effort.
          flatpak permission-set kde-authorized remote-desktop org.kde.krdpserver yes || true

          exec krdpserver \
            --username "${username}" \
            --password "$(cat "$dir/password")" \
            --certificate "$dir/krdp.crt" \
            --certificate-key "$dir/krdp.key" \
            --quality 80
        '';
      };
    in
    {
      # Keep the KCM's view of the world in sync with what the unit actually uses.
      programs.plasma.configFile."krdpserverrc"."General" = {
        Certificate = "${stateDir}/krdp.crt";
        CertificateKey = "${stateDir}/krdp.key";
        SystemUserEnabled = false;
      };

      programs.fish.shellAbbrs.krdp-password = "cat ${stateDir}/password";

      systemd.user.services."krdp-server" = {
        Unit = {
          Description = "KDE RDP Server (tailnet only)";
          # The portal service is what hands krdpserver the screencast + input
          # streams, so starting before it just burns Restart= attempts.
          After = [
            "graphical-session.target"
            "plasma-xdg-desktop-portal-kde.service"
          ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "exec";
          ExecStart = lib.getExe krdpStart;
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
