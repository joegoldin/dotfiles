function transcribe_latest
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
end

function transcribe_latest_summary
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
end

function transcribe_file
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
end

function transcribe_file_summary
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
end


