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
      name = "--history";
      short = "-n";
      arg = "POINTS";
      desc = "Number of data points to keep";
      default = "60";
    }
  ];
  body = ''
    import subprocess, time, signal, sys
    import plotext as plt

    UPS = "cyberpower@localhost"
    interval = int(_args.interval)
    maxpts = int(_args.history)

    def query(var):
        try:
            r = subprocess.run(["upsc", UPS, var], capture_output=True, text=True, timeout=5)
            return float(r.stdout.strip())
        except Exception:
            return 0.0

    charge, load, watts, va, in_volt, out_volt, runtime = [], [], [], [], [], [], []
    times = []
    t0 = time.monotonic()

    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    while True:
        charge.append(query("battery.charge"))
        load.append(query("ups.load"))
        watts.append(query("ups.realpower"))
        va.append(query("ups.power"))
        in_volt.append(query("input.voltage"))
        out_volt.append(query("output.voltage"))
        runtime.append(query("battery.runtime") / 60.0)
        times.append(round(time.monotonic() - t0))

        if len(times) > maxpts:
            for lst in (charge, load, watts, va, in_volt, out_volt, runtime, times):
                del lst[0]

        plt.clf()
        plt.subplots(2, 2)
        plt.theme("dark")

        def fmt(v):
            return str(int(v)) if v == int(v) else f"{v:.1f}"

        plt.subplot(1, 1)
        plt.title(f"Charge: {fmt(charge[-1])}%  Load: {fmt(load[-1])}%")
        plt.ylabel("%")
        plt.ylim(0, 100)
        plt.plot(times, charge, label="Charge")
        plt.plot(times, load, label="Load")

        plt.subplot(1, 2)
        plt.title(f"Power  W: {fmt(watts[-1])}  VA: {fmt(va[-1])}")
        plt.ylim(0, 1500)
        plt.plot(times, watts, label="W")
        plt.plot(times, va, label="VA")

        plt.subplot(2, 1)
        plt.title(f"Voltage  In: {fmt(in_volt[-1])}V  Out: {fmt(out_volt[-1])}V")
        plt.ylabel("V")
        plt.ylim(100, 140)
        plt.plot(times, in_volt, label="Input")
        plt.plot(times, out_volt, label="Output")

        plt.subplot(2, 2)
        plt.title(f"Runtime: {fmt(runtime[-1])} min")
        plt.ylabel("min")
        plt.plot(times, runtime)

        plt.show()
        time.sleep(interval)
  '';
}
