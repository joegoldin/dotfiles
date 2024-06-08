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
}
