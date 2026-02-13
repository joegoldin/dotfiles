{
  # Disable greeting
  fish_greeting = "echo '🐟'";

  transcribe_latest = ''
    # Find the most recent .m4a file in the ~/Downloads directory
    set latest_m4a (find ~/Downloads -name '*.m4a' -type f -print0 | xargs -0 stat -f "%m %N" | sort -rn | head -1 | cut -f2- -d" ")

    # Check if a file was found
    if test -z "$latest_m4a"
        echo "No .m4a files found in ~/Downloads."
        return 1
    end

    # Transcribe the file with speaker detection and labels
    echo "Transcribing: $latest_m4a"
    assemblyai transcribe "$latest_m4a" --speaker_labels=true --word_boost "Skillz" --boost_param default
  '';

  transcribe_latest_summary = ''
    # Find the most recent .m4a file in the ~/Downloads directory
    set latest_m4a (find ~/Downloads -name '*.m4a' -type f -print0 | xargs -0 stat -f "%m %N" | sort -rn | head -1 | cut -f2- -d" ")

    # Check if a file was found
    if test -z "$latest_m4a"
        echo "No .m4a files found in ~/Downloads."
        return 1
    end

    # Transcribe the file with speaker detection and labels, summarization in bullet points and key topics detection
    echo "Transcribing and summarizing: $latest_m4a"
    assemblyai transcribe "$latest_m4a" --speaker_labels=true --boost_param default --summarization=true --summary_model conversational --topic_detection=true # --word_boost "Skillz"
  '';

  transcribe_file = ''
    # Takes a file as a parameter and transcribes it
    set file_path $argv[1]

    # Check if the file exists
    if not test -f "$file_path"
        echo "File does not exist: $file_path"
        return 1
    end

    # Transcribe the file with speaker detection and labels
    echo "Transcribing: $file_path"
    assemblyai transcribe "$file_path" --speaker_labels=true --boost_param default # --word_boost "Skillz"
  '';

  transcribe_file_summary = ''
    # Takes a file as a parameter and transcribes it with summary
    set file_path $argv[1]

    # Check if the file exists
    if not test -f "$file_path"
        echo "File does not exist: $file_path"
        return 1
    end

    # Transcribe the file with speaker detection and labels, summarization in bullet points and key topics detection
    echo "Transcribing and summarizing: $file_path"
    assemblyai transcribe "$file_path" --speaker_labels=true --boost_param default --summarization=true --summary_mode bullets # --word_boost "Skillz"
  '';

  ask = "clai query $argv";

  rask = "clai -reply query $argv";

  image = "clai -photo-dir ~/Downloads photo $argv";

  askinput = ''
    # Read input from standard input (piped in)
    read input_lines

    # Get the argument (question)
    set question (string join ' ' $argv)

    ask "Given: \"$input_lines\"\n$question"
  '';

  raskinput = ''
    # Read input from standard input (piped in)
    read input_lines

    # Get the argument (question)
    set question (string join ' ' $argv)

    rask "Given: \"$input_lines\"\n$question"
  '';

  askraw = "clai -raw query $argv";

  askcopy = ''
    set output (askraw $argv)
    echo "$output"
    echo "$output" | pbcopy
  '';

  askrawcommand = ''
    set -l prompt "You are a terminal CLI tool that answers user questions by generating valid Fish shell commands. Your output should be ready to execute directly in the terminal, without any additional comments, notes, or formatting. NO MARKDOWN."
    clai -raw query "$prompt\nUser input: $argv"
  '';

  askcmd = ''
    set output (askrawcommand $argv)
    echo "$output"
    echo "$output" | pbcopy
  '';

  askprevcmd = ''
    # Get the argument (question)
    set question (string join ' ' $argv)

    ask "Previous Command: $history[1] \nGiven: $question"
  '';

  cask = "clai -chat-model claude-3-opus-20240229 query $argv";

  crask = "clai -chat-model claude-3-opus-20240229 -reply query $argv";

  cimage = "clai -chat-model claude-3-opus-20240229 -photo-dir ~/Downloads photo $argv";

  caskinput = ''
    # Read input from standard input (piped in)
    read input_lines

    # Get the argument (question)
    set question (string join ' ' $argv)

    cask "Given: \"$input_lines\"\n$question"
  '';

  craskinput = ''
    # Read input from standard input (piped in)
    read input_lines

    # Get the argument (question)
    set question (string join ' ' $argv)

    crask "Given: \"$input_lines\"\n$question"
  '';

  caskraw = "clai -chat-model claude-3-opus-20240229 -raw query $argv";

  caskcopy = ''
    set output (caskraw $argv)
    echo "$output"
    echo "$output" | pbcopy
  '';

  caskrawcommand = ''
    set -l prompt "You are a terminal CLI tool that answers user questions by generating valid Fish shell commands. Your output should be ready to execute directly in the terminal, without any additional comments, notes, or formatting. NO MARKDOWN."
    clai -chat-model claude-3-opus-20240229 -raw query "$prompt\nUser input: $argv"
  '';

  caskcmd = ''
    set output (caskrawcommand $argv)
    echo "$output"
    echo "$output" | pbcopy
  '';

  ghreview = ''
    # Wrapper for gh-pr-review with auto-detection of repo and PR
    #
    # Auto-detects repo and PR number from current directory/branch.
    # All arguments are passed through to gh pr-review.
    #
    # Usage:
    #   gh_review review view [--reviewer login] [--unresolved]
    #   gh_review threads list [--unresolved] [--mine]
    #   gh_review threads resolve --thread-id ID
    #   gh_review comments reply --thread-id ID --body "msg"
    #   gh_review review --start
    #   gh_review review --submit --review-id ID --event EVENT --body "msg"
    #
    # Override auto-detection with -R owner/repo and/or trailing PR number.

    set -l extra_args

    # Auto-detect repo unless -R is already provided
    if not contains -- -R $argv
      set -l repo (gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
      if test -z "$repo"
        echo "Error: Could not detect repository. Use -R owner/repo" >&2
        return 1
      end
      set extra_args -R $repo
    end

    # Check if last arg is a PR number (bare integer, not a flag value)
    set -l has_pr false
    if test (count $argv) -gt 0
      if string match -qr '^\d+$' -- $argv[-1]
        if test (count $argv) -lt 2; or not string match -qr '^--(tail|line|start-line)$' -- $argv[-2]
          set has_pr true
        end
      end
    end

    # Auto-detect PR number if not provided
    if not $has_pr
      set -l pr_number (gh pr view --json number -q .number 2>/dev/null)
      if test -z "$pr_number"
        echo "Error: Could not detect PR. Checkout a branch with an associated PR" >&2
        return 1
      end
      set extra_args $extra_args $pr_number
    end

    gh pr-review $argv $extra_args
  '';

  # Custom history expansion functions (replacing puffer-fish plugin)
  __expand_bang = ''
    switch (commandline -t)
      case '!'
        commandline -t $history[1]
      case '*'
        commandline -i '!'
    end
  '';

  __expand_lastarg = ''
    switch (commandline -t)
      case '!'
        # Get all tokens except the last one from the previous command
        set -l tokens (string split ' ' -- $history[1])
        set -l cmd_without_last (string join ' ' $tokens[1..-2])
        commandline -t $cmd_without_last
      case '*'
        commandline -i '.'
    end
  '';
}
