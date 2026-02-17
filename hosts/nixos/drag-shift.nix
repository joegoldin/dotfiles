# Right-click toggles Shift during a window drag (left-click held).
# Shift stays on until right-click again (toggle off) or left-click released.
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
                    pressed = event.value == 1
                    if pressed and state["left"]:
                        state["shift"] = not state["shift"]
                        ui.write(ecodes.EV_KEY, SHIFT_KEY, 1 if state["shift"] else 0)
                        ui.syn()
        except OSError:
            pass
    async def main():
        mice = find_mice()
        if not mice:
            print("No mouse devices found")
            return

        ui = UInput({ecodes.EV_KEY: [SHIFT_KEY]}, name="drag-shift-injector")
        state = {"left": False, "shift": False}

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
