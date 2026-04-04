{
  name = "ups";
  desc = "Query UPS status";
  usage = ''
    ups [command]

    Commands:
      (default)    Pretty-print UPS summary
      charts       Live-plot charge, load, power, voltage
      raw          Show all raw UPS variables
      charge       Battery charge percentage
      runtime      Battery runtime remaining
      status       UPS status
      load         Load percentage
      watts        Real power draw (watts)
      va           Apparent power (volt-amps)
      voltage      Input voltage'';
  examples = [
    { cmd = "ups"; desc = "Pretty-print UPS summary"; }
    { cmd = "ups charge"; desc = "Battery charge percentage"; }
    { cmd = "ups charge -r"; desc = "Raw charge value (no unit)"; }
    { cmd = "ups charts"; desc = "Live-plot UPS metrics"; }
  ];
  flags = [
    {
      name = "--raw";
      short = "-r";
      desc = "Output raw value (no formatting)";
      bool = true;
    }
  ];
  fish = ''
    set -l ups "cyberpower@localhost"

    if test (count $argv) -eq 0
      if set -q _flag_raw
        for var in ups.status battery.charge battery.runtime ups.load ups.realpower ups.power input.voltage
          echo "$var: "(upsc $ups $var 2>/dev/null)
        end
        return
      end

      # Default: pretty-print summary
      set -l charge (upsc $ups battery.charge 2>/dev/null)
      set -l runtime (upsc $ups battery.runtime 2>/dev/null)
      set -l ups_status (upsc $ups ups.status 2>/dev/null)
      set -l load (upsc $ups ups.load 2>/dev/null)
      set -l watts (upsc $ups ups.realpower 2>/dev/null)
      set -l va (upsc $ups ups.power 2>/dev/null)
      set -l voltage (upsc $ups input.voltage 2>/dev/null)

      # Format runtime as human-readable
      set -l mins (math --scale=0 "$runtime / 60")
      set -l secs (math --scale=0 "$runtime % 60")

      # Format status
      switch "$ups_status"
        case "OL"
          set ups_status "Online (AC power)"
        case "OB"
          set ups_status "On Battery"
        case "OB LB"
          set ups_status "On Battery (LOW)"
        case "OL CHRG"
          set ups_status "Online (Charging)"
      end

      printf "%-12s %s\n" "Status" "$ups_status"
      printf "%-12s %s%%\n" "Charge" "$charge"
      printf "%-12s %sm %ss\n" "Runtime" "$mins" "$secs"
      printf "%-12s %s%%\n" "Load" "$load"
      printf "%-12s %sW\n" "Power" "$watts"
      printf "%-12s %sVA\n" "Apparent" "$va"
      printf "%-12s %sV\n" "Voltage" "$voltage"
      return
    end

    switch $argv[1]
      case charts
        set -e argv[1]
        exec ups-charts $argv
      case raw
        upsc $ups
      case charge
        set -l val (upsc $ups battery.charge 2>/dev/null)
        if set -q _flag_raw
          echo $val
        else
          echo "$val%"
        end
      case runtime
        set -l val (upsc $ups battery.runtime 2>/dev/null)
        if set -q _flag_raw
          echo $val
        else
          set -l mins (math --scale=0 "$val / 60")
          set -l secs (math --scale=0 "$val % 60")
          echo "$mins"m "$secs"s
        end
      case status
        set -l val (upsc $ups ups.status 2>/dev/null)
        if set -q _flag_raw
          echo $val
        else
          switch "$val"
            case "OL"
              echo "Online (AC power)"
            case "OB"
              echo "On Battery"
            case "OB LB"
              echo "On Battery (LOW)"
            case "OL CHRG"
              echo "Online (Charging)"
            case '*'
              echo $val
          end
        end
      case load
        set -l val (upsc $ups ups.load 2>/dev/null)
        if set -q _flag_raw
          echo $val
        else
          echo "$val%"
        end
      case watts
        set -l val (upsc $ups ups.realpower 2>/dev/null)
        if set -q _flag_raw
          echo $val
        else
          echo "$val"W
        end
      case va
        set -l val (upsc $ups ups.power 2>/dev/null)
        if set -q _flag_raw
          echo $val
        else
          echo "$val"VA
        end
      case voltage
        set -l val (upsc $ups input.voltage 2>/dev/null)
        if set -q _flag_raw
          echo $val
        else
          echo "$val"V
        end
      case '*'
        # Pass through arbitrary variable names
        upsc $ups $argv[1]
    end
  '';
}
