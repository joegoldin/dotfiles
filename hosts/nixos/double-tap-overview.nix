# Double-tap F6 to trigger KDE Overview (mission control).
# Monitors keyboard input via evdev; fires Overview on two F6 presses within 300ms.
{
  pkgs,
  username,
  ...
}:
let
  python = pkgs.python3.withPackages (ps: [ ps.evdev ]);
  qdbus = "${pkgs.kdePackages.qttools}/bin/qdbus";

  double-tap-overview = pkgs.writeScriptBin "double-tap-overview" ''
    #!${python}/bin/python3
    import asyncio
    import os
    import subprocess
    import time
    import evdev
    from evdev import ecodes

    TRIGGER_KEY = ecodes.KEY_F6
    DOUBLE_TAP_WINDOW = 0.3  # seconds
    QDBUS = "${qdbus}"

    def find_keyboards():
        keyboards = []
        for path in evdev.list_devices():
            dev = evdev.InputDevice(path)
            caps = dev.capabilities(verbose=False)
            if ecodes.EV_KEY in caps:
                keys = caps[ecodes.EV_KEY]
                if TRIGGER_KEY in keys:
                    keyboards.append(dev)
        return keyboards

    def trigger_overview():
        subprocess.Popen(
            [
                QDBUS,
                "org.kde.kglobalaccel",
                "/component/kwin",
                "org.kde.kglobalaccel.Component.invokeShortcut",
                "Overview",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    async def monitor_device(dev, state):
        try:
            async for event in dev.async_read_loop():
                if event.type != ecodes.EV_KEY or event.code != TRIGGER_KEY:
                    continue
                # Only act on key-down (value 1), ignore repeat (2) and release (0)
                if event.value != 1:
                    continue
                now = time.monotonic()
                if now - state["last_press"] <= DOUBLE_TAP_WINDOW:
                    trigger_overview()
                    state["last_press"] = 0  # reset so triple-tap doesn't re-fire
                else:
                    state["last_press"] = now
        except OSError:
            pass

    async def main():
        keyboards = find_keyboards()
        if not keyboards:
            print("No keyboard devices with F6 found")
            return

        state = {"last_press": 0}

        print(f"Monitoring {len(keyboards)} device(s) for double-tap F6:")
        for kb in keyboards:
            print(f"  {kb.name} ({kb.path})")

        tasks = [asyncio.create_task(monitor_device(kb, state)) for kb in keyboards]
        await asyncio.gather(*tasks)

    asyncio.run(main())
  '';
in
{
  systemd.services."double-tap-overview" = {
    description = "Double-tap F6 to trigger KDE Overview";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "simple";
      User = username;
      Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";
      ExecStart = "${double-tap-overview}/bin/double-tap-overview";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
