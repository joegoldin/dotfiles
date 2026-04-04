{
  name = "rn";
  desc = "Print the current date and calendar";
  usage = "rn";
  fish = ''
    date "+%l:%M%p on %A, %B %e, %Y"
    echo
    cal | grep -E "\b"(date '+%e')"\b| "
  '';
}
