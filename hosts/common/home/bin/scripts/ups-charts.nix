{
  name = "ups-charts";
  desc = "Live-plot UPS charge, load, power, and voltage";
  type = "python";
  pythonPackages = [ "plotext" ];
  flags = [
    {
      name = "--interval";
      short = "-i";
      arg = "SECS";
      desc = "Poll interval in seconds";
      default = "2";
    }
    {
      name = "--window";
      short = "-w";
      arg = "MINS";
      desc = "Rolling time window in minutes (0=unlimited)";
      default = "5";
    }
  ];
  body = ''
    import subprocess, time, signal, sys
    from datetime import datetime
    import plotext as plt

    UPS = "cyberpower@localhost"
    interval = int(_args.interval)
    window_mins = int(_args.window)
    window_secs = window_mins * 60 if window_mins > 0 else 0

    def query(var):
        try:
            r = subprocess.run(["upsc", UPS, var], capture_output=True, text=True, timeout=5)
            return float(r.stdout.strip())
        except Exception:
            return 0.0

    charge, load, watts, va, in_volt, out_volt, runtime = [], [], [], [], [], [], []
    timestamps = []
    labels = []

    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    while True:
        now = time.time()
        charge.append(query("battery.charge"))
        load.append(query("ups.load"))
        watts.append(query("ups.realpower"))
        va.append(query("ups.power"))
        in_volt.append(query("input.voltage"))
        out_volt.append(query("output.voltage"))
        runtime.append(query("battery.runtime") / 60.0)
        timestamps.append(now)
        labels.append(datetime.fromtimestamp(now).strftime("%H:%M:%S"))

        # Trim to rolling window
        if window_secs > 0:
            cutoff = now - window_secs
            while timestamps and timestamps[0] < cutoff:
                for lst in (charge, load, watts, va, in_volt, out_volt, runtime, timestamps, labels):
                    del lst[0]

        window_label = f"{window_mins}m" if window_mins > 0 else "all"

        plt.clf()
        plt.subplots(2, 2)
        plt.theme("dark")

        def fmt(v):
            return str(int(v)) if v == int(v) else f"{v:.1f}"

        plt.subplot(1, 1)
        plt.title(f"Charge: {fmt(charge[-1])}%  Load: {fmt(load[-1])}%")
        plt.ylabel("%")
        plt.ylim(0, 100)
        plt.plot(labels, charge, label="Charge")
        plt.plot(labels, load, label="Load")
        plt.xlabel(f"window: {window_label}")

        plt.subplot(1, 2)
        plt.title(f"Power  W: {fmt(watts[-1])}  VA: {fmt(va[-1])}")
        plt.ylim(0, 1500)
        plt.plot(labels, watts, label="W")
        plt.plot(labels, va, label="VA")
        plt.xlabel(f"window: {window_label}")

        plt.subplot(2, 1)
        plt.title(f"Voltage  In: {fmt(in_volt[-1])}V  Out: {fmt(out_volt[-1])}V")
        plt.ylabel("V")
        plt.ylim(100, 140)
        plt.plot(labels, in_volt, label="Input")
        plt.plot(labels, out_volt, label="Output")
        plt.xlabel(f"window: {window_label}")

        plt.subplot(2, 2)
        plt.title(f"Runtime: {fmt(runtime[-1])} min")
        plt.ylabel("min")
        plt.plot(labels, runtime)
        plt.xlabel(f"window: {window_label}")

        plt.show()
        time.sleep(interval)
  '';
}
