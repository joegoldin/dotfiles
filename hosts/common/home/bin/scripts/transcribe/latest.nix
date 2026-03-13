{
  name = "latest";
  desc = "Transcribe the most recent .m4a file in ~/Downloads";
  type = "fish";
  body = ''
    set latest_m4a (find ~/Downloads -name '*.m4a' -type f -print0 | xargs -0 stat -f "%m %N" | sort -rn | head -1 | cut -f2- -d" ")

    if test -z "$latest_m4a"
        echo "No .m4a files found in ~/Downloads."
        exit 1
    end

    echo "Transcribing: $latest_m4a"
    assemblyai transcribe "$latest_m4a" --speaker_labels=true --word_boost "Skillz" --boost_param default
  '';
}
