# Right-click toggles Shift during a window drag (left-click held).
# Shift stays on until right-click again (toggle off) or left-click released.
{
  pkgs,
  username,
  ...
}:
let
  python = pkgs.python3.withPackages (ps: [
    ps.evdev
    ps.inotify-simple
  ]);

  drag-shift = pkgs.writeScriptBin "drag-shift" ''
    #!${python}/bin/python3
    import asyncio
    import evdev
    from evdev import UInput, ecodes
    from inotify_simple import INotify, flags
    from pathlib import Path

    SHIFT_KEY = ecodes.KEY_LEFTSHIFT
    INPUT_DIR = "/dev/input"

    def is_mouse(path):
        try:
            dev = evdev.InputDevice(path)
            caps = dev.capabilities(verbose=False)
            if ecodes.EV_REL in caps and ecodes.EV_KEY in caps:
                keys = caps[ecodes.EV_KEY]
                if ecodes.BTN_LEFT in keys and ecodes.BTN_RIGHT in keys:
                    return dev
        except (OSError, PermissionError):
            pass
        return None

    async def monitor_mouse(mouse, ui, state, tracked):
        print(f"  Monitoring: {mouse.name} ({mouse.path})")
        try:
            async for event in mouse.async_read_loop():
                if event.type != ecodes.EV_KEY:
                    continue

                if event.code == ecodes.BTN_LEFT:
                    state["left"] = event.value in (1, 2)
                    if not state["left"] and state["shift"]:
                        ui.write(ecodes.EV_KEY, SHIFT_KEY, 0)
                        ui.syn()
                        state["shift"] = False

                elif event.code == ecodes.BTN_RIGHT:
                    pressed = event.value == 1
                    if pressed and state["left"]:
                        state["shift"] = not state["shift"]
                        ui.write(ecodes.EV_KEY, SHIFT_KEY, 1 if state["shift"] else 0)
                        ui.syn()
        except OSError:
            print(f"  Disconnected: {mouse.name} ({mouse.path})")
        finally:
            tracked.discard(mouse.path)

    async def watch_devices(ui, state, tracked):
        inotify = INotify()
        inotify.add_watch(INPUT_DIR, flags.CREATE)
        loop = asyncio.get_event_loop()
        while True:
            await loop.run_in_executor(None, inotify.read)
            await asyncio.sleep(0.5)  # let device settle
            for path in evdev.list_devices():
                if path in tracked:
                    continue
                dev = is_mouse(path)
                if dev:
                    tracked.add(path)
                    asyncio.create_task(monitor_mouse(dev, ui, state, tracked))

    async def main():
        ui = UInput({ecodes.EV_KEY: [SHIFT_KEY]}, name="drag-shift-injector")
        state = {"left": False, "shift": False}
        tracked = set()

        print("Scanning for mouse devices...")
        for path in evdev.list_devices():
            dev = is_mouse(path)
            if dev:
                tracked.add(path)
                asyncio.create_task(monitor_mouse(dev, ui, state, tracked))

        if not tracked:
            print("No mouse devices found yet, watching for new ones...")

        await watch_devices(ui, state, tracked)

    asyncio.run(main())
  '';
in
{
  systemd.services."drag-shift" = {
    description = "Inject Shift when left+right mouse buttons held during window drag";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "simple";
      User = username;
      ExecStart = "${drag-shift}/bin/drag-shift";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
