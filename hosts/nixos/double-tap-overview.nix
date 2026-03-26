# Double-tap F6 or double-click middle mouse to trigger KDE Overview (mission control).
# Monitors keyboard/mouse input via evdev; fires Overview on two presses within 300ms.
# While Overview is active, middle mouse button is blocked to prevent closing windows.
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
    import subprocess
    import time
    import evdev
    from evdev import ecodes, UInput

    TRIGGER_KEYS = {ecodes.KEY_F6, ecodes.BTN_MIDDLE}
    DOUBLE_TAP_WINDOW = 0.3  # seconds
    QDBUS = "${qdbus}"

    def find_devices():
        devices = []
        for path in evdev.list_devices():
            dev = evdev.InputDevice(path)
            caps = dev.capabilities(verbose=False)
            if ecodes.EV_KEY in caps:
                keys = caps[ecodes.EV_KEY]
                if TRIGGER_KEYS & set(keys):
                    devices.append(dev)
        return devices

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

    def is_overview_active():
        try:
            result = subprocess.run(
                [QDBUS, "org.kde.KWin", "/Effects",
                 "org.kde.KWin.Effects.isEffectActive", "overview"],
                capture_output=True, text=True, timeout=1,
            )
            return result.stdout.strip() == "true"
        except Exception:
            return False

    def grab_mice(state):
        for dev in state["mice"]:
            if dev.path in state["grabbed"]:
                continue
            try:
                caps = dev.capabilities()
                caps.pop(ecodes.EV_SYN, None)
                virtual = UInput(events=caps, name=f"{dev.name} (filtered)")
                dev.grab()
                state["grabbed"][dev.path] = virtual
            except Exception as e:
                print(f"Failed to grab {dev.name}: {e}")

    def ungrab_mice(state):
        for dev in state["mice"]:
            virtual = state["grabbed"].pop(dev.path, None)
            if virtual:
                try:
                    dev.ungrab()
                except Exception:
                    pass
                try:
                    virtual.close()
                except Exception:
                    pass

    async def watch_overview_close(state):
        await asyncio.sleep(0.4)
        while is_overview_active():
            await asyncio.sleep(0.15)
        ungrab_mice(state)

    async def monitor_device(dev, state):
        try:
            async for event in dev.async_read_loop():
                # While grabbed, forward all events except BTN_MIDDLE
                if dev.path in state["grabbed"]:
                    if event.type == ecodes.EV_KEY and event.code == ecodes.BTN_MIDDLE:
                        continue
                    state["grabbed"][dev.path].write_event(event)
                    continue

                # Double-tap detection
                if event.type != ecodes.EV_KEY or event.code not in TRIGGER_KEYS:
                    continue
                if event.value != 1:
                    continue
                now = time.monotonic()
                if now - state["last_press"] <= DOUBLE_TAP_WINDOW:
                    trigger_overview()
                    state["last_press"] = 0
                    if not state["grabbed"]:
                        grab_mice(state)
                        asyncio.create_task(watch_overview_close(state))
                else:
                    state["last_press"] = now
        except OSError:
            pass

    async def main():
        devices = find_devices()
        if not devices:
            print("No devices with F6 or middle mouse button found")
            return

        mice = [d for d in devices
                if ecodes.BTN_MIDDLE in d.capabilities(verbose=False).get(ecodes.EV_KEY, [])]

        state = {
            "last_press": 0,
            "mice": mice,
            "grabbed": {},
        }

        print(f"Monitoring {len(devices)} device(s) for double-tap F6 / middle-click:")
        for dev in devices:
            kind = "mouse" if dev in mice else "keyboard"
            print(f"  [{kind}] {dev.name} ({dev.path})")

        tasks = [asyncio.create_task(monitor_device(dev, state)) for dev in devices]
        await asyncio.gather(*tasks)

    asyncio.run(main())
  '';
in
{
  systemd.services."double-tap-overview" = {
    description = "Double-tap F6 or middle-click to trigger KDE Overview";
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
