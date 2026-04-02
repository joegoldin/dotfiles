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

    charge, load, watts, va, voltage = [], [], [], [], []
    times = []
    t0 = time.monotonic()

    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    while True:
        charge.append(query("battery.charge"))
        load.append(query("ups.load"))
        watts.append(query("ups.realpower"))
        va.append(query("ups.power"))
        voltage.append(query("input.voltage"))
        times.append(round(time.monotonic() - t0))

        if len(times) > maxpts:
            for lst in (charge, load, watts, va, voltage, times):
                del lst[0]

        plt.clf()
        plt.subplots(2, 2)
        plt.theme("dark")

        plt.subplot(1, 1)
        plt.title("Charge")
        plt.ylabel("%")
        plt.ylim(0, 100)
        plt.plot(times, charge)

        plt.subplot(1, 2)
        plt.title("Load")
        plt.ylabel("%")
        plt.ylim(0, 100)
        plt.plot(times, load)

        plt.subplot(2, 1)
        plt.title("Power")
        plt.ylim(0, 1500)
        plt.plot(times, watts, label="W")
        plt.plot(times, va, label="VA")

        plt.subplot(2, 2)
        plt.title("Voltage")
        plt.ylabel("V")
        plt.ylim(100, 140)
        plt.plot(times, voltage)

        plt.show()
        time.sleep(interval)
  '';
}
