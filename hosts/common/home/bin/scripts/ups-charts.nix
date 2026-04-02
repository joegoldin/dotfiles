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

    charge, load, watts, va, in_volt, out_volt = [], [], [], [], [], []
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
        times.append(round(time.monotonic() - t0))

        if len(times) > maxpts:
            for lst in (charge, load, watts, va, in_volt, out_volt, times):
                del lst[0]

        plt.clf()
        plt.subplots(1, 3)
        plt.theme("dark")

        def fmt(v):
            return str(int(v)) if v == int(v) else f"{v:.1f}"

        plt.subplot(1, 1)
        plt.title("Charge / Load")
        plt.ylabel("%")
        plt.ylim(0, 100)
        plt.plot(times, charge, label=f"Charge: {fmt(charge[-1])}%")
        plt.plot(times, load, label=f"Load: {fmt(load[-1])}%")

        plt.subplot(1, 2)
        plt.title("Power")
        plt.ylim(0, 1500)
        plt.plot(times, watts, label=f"W: {fmt(watts[-1])}")
        plt.plot(times, va, label=f"VA: {fmt(va[-1])}")

        plt.subplot(1, 3)
        plt.title("Voltage")
        plt.ylabel("V")
        plt.ylim(100, 140)
        plt.plot(times, in_volt, label=f"In: {fmt(in_volt[-1])}V")
        plt.plot(times, out_volt, label=f"Out: {fmt(out_volt[-1])}V")

        plt.show()
        time.sleep(interval)
  '';
}
