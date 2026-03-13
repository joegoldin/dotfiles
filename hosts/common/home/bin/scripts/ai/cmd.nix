{
  name = "cmd";
  desc = "Generate a fish shell command from a question and copy it";
  type = "fish";
  body = ''
    set -l prompt "You are a terminal CLI tool that answers user questions by generating valid Fish shell commands. Your output should be ready to execute directly in the terminal, without any additional comments, notes, or formatting. NO MARKDOWN."
    set output (clai -raw query "$prompt\nUser input: $argv")
    echo "$output"
    echo "$output" | pbcopy
  '';
}
