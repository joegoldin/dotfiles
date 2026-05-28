# Press mouse forward + back within a short window to trigger KDE Overview.
# Passive evdev monitor; apps still receive the button events normally.
{
  pkgs,
  username,
  ...
}:
let
  python = pkgs.python3.withPackages (ps: [ ps.evdev ]);
  # qdbus from qttools 6.11 SEGVs in QDBusConnectionManager's destructor during
  # exit handlers (the shortcut still fires, but the non-zero exit dirties the
  # journal). dbus-send is clean.
  dbus-send = "${pkgs.dbus}/bin/dbus-send";

  overview-hotkey = pkgs.writeScriptBin "overview-hotkey" ''
    #!${python}/bin/python3
    import asyncio
    import subprocess
    import time
    import evdev
    from evdev import ecodes

    CHORD_WINDOW = 0.10  # seconds
    BACK_BUTTON = ecodes.BTN_SIDE
    FORWARD_BUTTON = ecodes.BTN_EXTRA
    CHORD_BUTTONS = {BACK_BUTTON, FORWARD_BUTTON}
    DBUS_SEND = "${dbus-send}"

    def find_devices():
        devices = []
        for path in evdev.list_devices():
            dev = evdev.InputDevice(path)
            caps = dev.capabilities(verbose=False)
            if ecodes.EV_KEY in caps:
                keys = set(caps[ecodes.EV_KEY])
                if BACK_BUTTON in keys and FORWARD_BUTTON in keys:
                    devices.append(dev)
        return devices

    def trigger_overview():
        subprocess.Popen(
            [
                DBUS_SEND,
                "--type=method_call",
                "--dest=org.kde.kglobalaccel",
                "/component/kwin",
                "org.kde.kglobalaccel.Component.invokeShortcut",
                "string:Overview",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    async def monitor_device(dev, state):
        try:
            async for event in dev.async_read_loop():
                if event.type != ecodes.EV_KEY or event.code not in CHORD_BUTTONS:
                    continue
                # Only act on key-down (value 1); ignore repeat (2) and release (0)
                if event.value != 1:
                    continue
                now = time.monotonic()
                other = FORWARD_BUTTON if event.code == BACK_BUTTON else BACK_BUTTON
                if now - state[other] <= CHORD_WINDOW:
                    trigger_overview()
                    state[BACK_BUTTON] = 0
                    state[FORWARD_BUTTON] = 0
                else:
                    state[event.code] = now
        except OSError:
            pass

    async def main():
        devices = find_devices()
        if not devices:
            print("No devices with mouse forward+back buttons found")
            return

        state = {BACK_BUTTON: 0, FORWARD_BUTTON: 0}

        print(f"Monitoring {len(devices)} device(s) for forward+back chord:")
        for dev in devices:
            print(f"  {dev.name} ({dev.path})")

        tasks = [asyncio.create_task(monitor_device(dev, state)) for dev in devices]
        await asyncio.gather(*tasks)

    asyncio.run(main())
  '';
in
{
  systemd.services."overview-hotkey" = {
    description = "Mouse forward+back chord to trigger KDE Overview";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "simple";
      User = username;
      Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";
      ExecStart = "${overview-hotkey}/bin/overview-hotkey";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
