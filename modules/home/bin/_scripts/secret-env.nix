{
  name = "secret-env";
  desc = "Load an age-encrypted KEY=VALUE file into the current shell";
  usage = "secret-env <file.age>";
  params = [
    {
      name = "FILE";
      desc = "age-encrypted KEY=VALUE file";
      completions = "__fish_complete_path";
    }
  ];
  examples = [
    {
      cmd = "secret-env scripts/e2e/credentials.age";
      desc = "Export every key in the file into this shell";
    }
  ];
  hostOnly = true;
  # A fish *function*, not a script: `secret-helper dotenv` runs as a child
  # process and so cannot touch this shell's environment, and neither could a
  # wrapper script. A function runs in the current shell, which is the whole
  # point — it turns
  #   set -a; eval "$(secret-helper decrypt-file creds.age)"; set +a
  # into
  #   secret-env creds.age
  # and the plaintext never reaches disk, only this shell's memory.
  function = ''
    if test (count $argv) -lt 1
      echo "usage: secret-env <file.age>" >&2
      return 1
    end
    if not test -f $argv[1]
      echo "secret-env: $argv[1] does not exist" >&2
      return 1
    end

    # Capture first so a failed decrypt (locked 1Password, wrong key) leaves the
    # environment untouched instead of half-applied.
    set -l assignments (secret-helper dotenv $argv[1] fish)
    or return 1

    if test (count $assignments) -eq 0
      echo "secret-env: no KEY=VALUE lines in $argv[1]" >&2
      return 1
    end

    for line in $assignments
      echo $line | source
    end
    echo "Loaded "(count $assignments)" variables from $argv[1]"
  '';
}
