{
  name = "file-summary";
  desc = "Transcribe and summarize an audio file";
  type = "fish";
  params = [
    { name = "file"; desc = "Path to audio file"; }
  ];
  body = ''
    set file_path $argv[1]

    if not test -f "$file_path"
        echo "File does not exist: $file_path"
        exit 1
    end

    echo "Transcribing and summarizing: $file_path"
    assemblyai transcribe "$file_path" --speaker_labels=true --boost_param default --summarization=true --summary_mode bullets
  '';
}
