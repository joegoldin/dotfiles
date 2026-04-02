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
    elapsed = []
    t0 = time.monotonic()

    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    def elapsed_label(secs):
        m = int(secs) // 60
        s = int(secs) % 60
        if m == 0:
            return f"{s}s"
        elif s == 0:
            return f"{m}m"
        else:
            return f"{m}m{s}s"

    while True:
        now = time.monotonic()
        charge.append(query("battery.charge"))
        load.append(query("ups.load"))
        watts.append(query("ups.realpower"))
        va.append(query("ups.power"))
        in_volt.append(query("input.voltage"))
        out_volt.append(query("output.voltage"))
        runtime.append(query("battery.runtime") / 60.0)
        elapsed.append(now - t0)

        # Trim to rolling window
        if window_secs > 0:
            cutoff = elapsed[-1] - window_secs
            while elapsed and elapsed[0] < cutoff:
                for lst in (charge, load, watts, va, in_volt, out_volt, runtime, elapsed):
                    del lst[0]

        xlabels = [elapsed_label(e) for e in elapsed]

        plt.clf()
        plt.subplots(2, 2)
        plt.theme("dark")

        def fmt(v):
            return str(int(v)) if v == int(v) else f"{v:.1f}"

        plt.subplot(1, 1)
        plt.title(f"Charge: {fmt(charge[-1])}%  Load: {fmt(load[-1])}%")
        plt.ylabel("%")
        plt.ylim(0, 100)
        plt.plot(xlabels, charge, label="Charge")
        plt.plot(xlabels, load, label="Load")

        plt.subplot(1, 2)
        plt.title(f"Power  W: {fmt(watts[-1])}  VA: {fmt(va[-1])}")
        plt.ylim(0, 1500)
        plt.plot(xlabels, watts, label="W")
        plt.plot(xlabels, va, label="VA")

        plt.subplot(2, 1)
        plt.title(f"Voltage  In: {fmt(in_volt[-1])}V  Out: {fmt(out_volt[-1])}V")
        plt.ylabel("V")
        plt.ylim(100, 140)
        plt.plot(xlabels, in_volt, label="Input")
        plt.plot(xlabels, out_volt, label="Output")

        plt.subplot(2, 2)
        plt.title(f"Runtime: {fmt(runtime[-1])} min")
        plt.ylabel("min")
        plt.plot(xlabels, runtime)

        plt.show()
        time.sleep(interval)
  '';
}
