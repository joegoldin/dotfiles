# BlueZ with the DualSense-friendly HID setup.
#
# BlueZ 5.x defaults to userspace HID (uhid) for input devices; on this kernel
# that path drops the DualSense a few seconds/minutes into a session. Handing
# HID back to the kernel hidp driver keeps the pad connected.
_: {
  den.aspects.bluetooth.nixos = _: {
    hardware.bluetooth = {
      enable = true;
      input.General.UserspaceHID = false;
    };
  };
}
