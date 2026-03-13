{
  name = "latest-summary";
  desc = "Transcribe and summarize the most recent .m4a in ~/Downloads";
  type = "fish";
  body = ''
    set latest_m4a (find ~/Downloads -name '*.m4a' -type f -print0 | xargs -0 stat -f "%m %N" | sort -rn | head -1 | cut -f2- -d" ")

    if test -z "$latest_m4a"
        echo "No .m4a files found in ~/Downloads."
        exit 1
    end

    echo "Transcribing and summarizing: $latest_m4a"
    assemblyai transcribe "$latest_m4a" --speaker_labels=true --boost_param default --summarization=true --summary_model conversational --topic_detection=true
  '';
}
