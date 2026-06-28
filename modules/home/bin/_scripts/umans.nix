# umans: run Claude Code against the umans-coder endpoint (api.code.umans.ai),
# authenticating with the raw umans_api_key agenix secret (/run/agenix/umans_api_key).
# Any extra args pass straight through to `claude`.
{
  name = "umans";
  desc = "Run Claude Code against the umans-coder endpoint";
  examples = [
    {
      cmd = "umans";
      desc = "Open an interactive Claude session on umans-coder";
    }
    {
      cmd = "umans -p 'summarize this repo'";
      desc = "One-shot prompt (extra args pass through to claude)";
    }
  ];
  fish = ''
    set -l key_file /run/agenix/umans_api_key
    if not test -r "$key_file"
      echo "umans: missing secret $key_file (age.secrets.umans_api_key not deployed on this host)" >&2
      return 1
    end

    set -gx ANTHROPIC_BASE_URL https://api.code.umans.ai
    set -gx ANTHROPIC_AUTH_TOKEN (cat "$key_file")

    exec claude --model umans-coder $argv
  '';
}
