{
  name = "claude-cmd";
  desc = "Generate a fish command using Claude Opus and copy it";
  type = "fish";
  body = ''
    set -l prompt "You are a terminal CLI tool that answers user questions by generating valid Fish shell commands. Your output should be ready to execute directly in the terminal, without any additional comments, notes, or formatting. NO MARKDOWN."
    set output (clai -chat-model claude-3-opus-20240229 -raw query "$prompt\nUser input: $argv")
    echo "$output"
    echo "$output" | pbcopy
  '';
}
