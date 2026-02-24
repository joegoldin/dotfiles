{
  name = "pastas";
  desc = "Watch clipboard and print changes";
  usage = "pastas";
  type = "fish";
  body = ''
    trap 'exit 0' SIGINT

    set last_value '''

    while true
        set value (pasta)

        if test "$last_value" != "$value"
            echo $value
            set last_value $value
        end

        sleep 0.1
    end
  '';
}
