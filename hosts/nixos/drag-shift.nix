# Injects Shift key when both left and right mouse buttons are held simultaneously.
# Useful for KDE Plasma window drag + right-click → Shift modifier workflows.
{
  pkgs,
  username,
  ...
}: let
  python = pkgs.python3.withPackages (ps: [ps.evdev]);

  drag-shift = pkgs.writeScriptBin "drag-shift" ''
    #!${python}/bin/python3
    import asyncio
    import evdev
    from evdev import UInput, ecodes

    SHIFT_KEY = ecodes.KEY_LEFTSHIFT

    def find_mice():
        """Find all mouse devices."""
        mice = []
        for path in evdev.list_devices():
            dev = evdev.InputDevice(path)
            caps = dev.capabilities(verbose=False)
            if ecodes.EV_REL in caps and ecodes.EV_KEY in caps:
                keys = caps[ecodes.EV_KEY]
                if ecodes.BTN_LEFT in keys and ecodes.BTN_RIGHT in keys:
                    mice.append(dev)
        return mice

    async def monitor_mouse(mouse, ui, state):
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
                    state["right"] = event.value in (1, 2)

                    if state["right"] and state["left"] and not state["shift"]:
                        ui.write(ecodes.EV_KEY, SHIFT_KEY, 1)
                        ui.syn()
                        state["shift"] = True
                    elif not state["right"] and state["shift"]:
                        ui.write(ecodes.EV_KEY, SHIFT_KEY, 0)
                        ui.syn()
                        state["shift"] = False
        except OSError:
            pass  # Device disconnected

    async def main():
        mice = find_mice()
        if not mice:
            print("No mouse devices found")
            return

        ui = UInput({ecodes.EV_KEY: [SHIFT_KEY]}, name="drag-shift-injector")
        state = {"left": False, "right": False, "shift": False}

        print(f"Monitoring {len(mice)} mouse device(s):")
        for m in mice:
            print(f"  {m.name} ({m.path})")

        tasks = [asyncio.create_task(monitor_mouse(m, ui, state)) for m in mice]
        await asyncio.gather(*tasks)

    asyncio.run(main())
  '';
in {
  systemd.services."drag-shift" = {
    description = "Inject Shift when left+right mouse buttons held during window drag";
    wantedBy = ["multi-user.target"];
    after = ["systemd-udevd.service"];
    serviceConfig = {
      Type = "simple";
      User = username;
      ExecStart = "${drag-shift}/bin/drag-shift";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
