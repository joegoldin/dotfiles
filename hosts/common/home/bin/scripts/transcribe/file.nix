{
  name = "file";
  desc = "Transcribe an audio file with speaker detection";
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

    echo "Transcribing: $file_path"
    assemblyai transcribe "$file_path" --speaker_labels=true --boost_param default
  '';
}
