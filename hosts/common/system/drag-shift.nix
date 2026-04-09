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

    async def reconcile(ui, state, tracked):
        # Periodically resync state with the kernel's view of the physical
        # buttons. Guards against missed release edges (VT switch, grabs,
        # suspend quirks) that would otherwise leave state["left"] stuck.
        while True:
            await asyncio.sleep(1.0)
            physical_left = False
            for dev in list(tracked.values()):
                try:
                    if ecodes.BTN_LEFT in dev.active_keys():
                        physical_left = True
                        break
                except OSError:
                    pass
            if state["left"] and not physical_left:
                state["left"] = False
                if state["shift"]:
                    ui.write(ecodes.EV_KEY, SHIFT_KEY, 0)
                    ui.syn()
                    state["shift"] = False

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
            tracked.pop(mouse.path, None)
            # Device vanished (e.g. across suspend) mid-drag: we may have
            # missed the BTN_LEFT/BTN_RIGHT release events, leaving state
            # stuck. Reset and make sure shift isn't left held down.
            if state["shift"]:
                ui.write(ecodes.EV_KEY, SHIFT_KEY, 0)
                ui.syn()
            state["left"] = False
            state["shift"] = False

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
                    tracked[path] = dev
                    asyncio.create_task(monitor_mouse(dev, ui, state, tracked))

    async def main():
        ui = UInput({ecodes.EV_KEY: [SHIFT_KEY]}, name="drag-shift-injector")
        state = {"left": False, "shift": False}
        tracked = {}

        print("Scanning for mouse devices...")
        for path in evdev.list_devices():
            dev = is_mouse(path)
            if dev:
                tracked[path] = dev
                asyncio.create_task(monitor_mouse(dev, ui, state, tracked))

        asyncio.create_task(reconcile(ui, state, tracked))

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
      Restart = "always";
      RestartSec = 2;
    };
  };

  # Restart drag-shift after suspend/hibernate/hybrid-sleep so the virtual
  # uinput device gets re-announced to the compositor on resume.
  systemd.services."drag-shift-resume" = {
    description = "Restart drag-shift after resume";
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart drag-shift.service";
    };
  };
}
