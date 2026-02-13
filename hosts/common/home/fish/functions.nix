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
    # Wrapper for gh-pr-review with auto-detection, bot filtering, and code context
    #
    # Usage:
    #   ghreview [flags] [subcommand] [args...]
    #
    # Custom flags:
    #   --no-bots    Exclude bot authors (login ending in [bot]) from output
    #   --raw        Output raw JSON (skip jq pretty-printing)
    #   --no-code    Skip injecting source code context into comments
    #   --pretty     Render as readable markdown instead of JSON
    #
    # Repo and PR auto-detected from current directory/branch.
    # Override with -R owner/repo and/or --pr NUMBER.
    # Defaults to 'review view' if no subcommand given.
    #
    # Examples:
    #   ghreview
    #   ghreview --pretty
    #   ghreview --pretty --no-bots
    #   ghreview --no-code
    #   ghreview review view --unresolved --reviewer octocat
    #   ghreview threads list --mine
    #   ghreview threads resolve --thread-id PRRT_xxx
    #   ghreview comments reply --thread-id PRRT_xxx --body "fixed"

    set -l no_bots false
    set -l raw false
    set -l with_code true
    set -l pretty false
    set -l pass_args

    # Parse custom flags, pass everything else through
    for arg in $argv
      switch $arg
        case '--no-bots'
          set no_bots true
        case '--raw'
          set raw true
        case '--no-code'
          set with_code false
        case '--pretty'
          set pretty true
        case '*'
          set -a pass_args $arg
      end
    end

    # Default to 'review view' if no subcommand given
    if test (count $pass_args) -eq 0
      set pass_args review view
    end

    set -l extra_args

    # Auto-detect repo unless -R already provided
    if not contains -- -R $pass_args
      set -l repo (gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
      if test -z "$repo"
        echo "Error: Could not detect repository. Use -R owner/repo" >&2
        return 1
      end
      set extra_args -R $repo
    end

    # Auto-detect PR unless --pr already provided
    if not contains -- --pr $pass_args
      set -l pr_number (gh pr view --json number -q .number 2>/dev/null)
      if test -z "$pr_number"
        echo "Error: Could not detect PR. Checkout a branch with an associated PR" >&2
        return 1
      end
      set extra_args $extra_args --pr $pr_number
    end

    # Run command to temp file for pipeline processing
    set -l tmpfile (mktemp)
    gh pr-review $pass_args $extra_args > $tmpfile

    # Detect output type: "reviews" (review view), "threads" (threads list), or "other"
    set -l output_type (jq -r 'if type == "object" and .reviews then "reviews" else if type == "array" and length > 0 and (.[0] | has("threadId")) then "threads" else "other" end end' $tmpfile)

    # Enrich with source code context if --code
    if $with_code; and test "$output_type" != other
      set -l ctxfile (mktemp)
      echo -n > $ctxfile

      # Extract path:line pairs depending on output type
      if test "$output_type" = reviews
        set -l locs (jq -r '[.reviews[]?.comments[]? | select(.path and .line) | "\(.path):\(.line)"] | unique[]' $tmpfile)
      else
        set -l locs (jq -r '[.[]? | select(.path and .line) | "\(.path):\(.line)"] | unique[]' $tmpfile)
      end

      for loc in $locs
        set -l parts (string split ':' -- $loc)
        set -l file $parts[1]
        set -l line_num $parts[2]
        if test -f "$file"
          set -l ctx_start (math "max(1, $line_num - 3)")
          set -l ctx_end (math "$line_num + 3")
          sed -n "$ctx_start,$ctx_end"p "$file" | awk -v n=$ctx_start '{printf "%d: %s\n", NR+n-1, $0}' | jq -Rs --arg key "$loc" '{($key): .}' >> $ctxfile
        end
      end

      set -l ctxlookup (mktemp)
      jq -s 'add // {}' $ctxfile > $ctxlookup

      if test "$output_type" = reviews
        jq --slurpfile ctx $ctxlookup '.reviews |= [.[] | if .comments then .comments |= [.[] | if .path and .line then . + {code_context: ($ctx[0]["\(.path):\(.line)"] // null)} else . end] else . end]' $tmpfile > "$tmpfile.tmp"
      else
        jq --slurpfile ctx $ctxlookup '[.[] | if .path and .line then . + {code_context: ($ctx[0]["\(.path):\(.line)"] // null)} else . end]' $tmpfile > "$tmpfile.tmp"
      end
      mv "$tmpfile.tmp" $tmpfile
      rm -f $ctxfile $ctxlookup
    end

    # Filter bots if --no-bots (reviews output has author_login)
    if $no_bots; and test "$output_type" = reviews
      jq 'walk(if type == "array" then map(select(if .author_login? then (.author_login | test("\\[bot\\]$") | not) else true end)) else . end)' $tmpfile > "$tmpfile.tmp"
      mv "$tmpfile.tmp" $tmpfile
    end

    # Output
    if $pretty; and test "$output_type" = reviews
      jq -r '
        [.reviews[]? | select((.body and (.body | length > 0)) or (.comments and (.comments | length > 0)))] |
        map(
          "## " + .author_login + " — " + .state +
          (if .submitted_at then " (" + (.submitted_at | split("T") | .[0]) + ")" else "" end) +
          (if .body and (.body | length > 0) then "\n\n" + .body else "" end) +
          (if .comments and (.comments | length > 0) then "\n\n" +
            ([.comments[] |
              "### `" + .path + ":" + (.line | tostring) + "`" +
              (if .is_resolved then " ✅" else "" end) +
              (if .is_outdated then " ~~outdated~~" else "" end) +
              (if .code_context then
                "\n\n```" + (.path | split(".") | last) + "\n" + (.code_context | rtrimstr("\n")) + "\n```"
              else "" end) +
              "\n\n**" + .author_login + ":** " + .body +
              (if .thread_comments and (.thread_comments | length > 0) then
                "\n" + ([.thread_comments[] |
                  "\n> **" + .author_login + ":** " + .body
                ] | join(""))
              else "" end)
            ] | join("\n\n---\n\n"))
          else "" end)
        ) | join("\n\n===\n\n")
      ' $tmpfile
    else if $pretty; and test "$output_type" = threads
      jq -r '
        map(
          "### `" + .path + ":" + (.line | tostring) + "` — " + .threadId +
          (if .isResolved then " ✅" else "" end) +
          (if .isOutdated then " ~~outdated~~" else "" end) +
          (if .code_context then
            "\n\n```" + (.path | split(".") | last) + "\n" + (.code_context | rtrimstr("\n")) + "\n```"
          else "" end) +
          "\n\nUpdated: " + (.updatedAt | split("T") | .[0])
        ) | join("\n\n---\n\n")
      ' $tmpfile
    else if $raw
      cat $tmpfile
    else
      jq . $tmpfile
    end

    rm -f $tmpfile
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
