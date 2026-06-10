_: {
  programs.audiomemo = {
    enable = true;
    # Host-specific device settings live in hosts/darwin/packages/audiomemo.nix
    # and hosts/nixos/packages/audiomemo.nix; home-manager deep-merges them
    # with these.
    settings = {
      onboard_version = 1;
      record.output_dir = "~/Recordings";
      transcribe = {
        default_backend = "elevenlabs";
        elevenlabs = {
          api_key_file = "/run/agenix/elevenlabs_api_key";
          model = "scribe_v2";
          diarize = true;
        };
        deepgram = {
          api_key_file = "/run/agenix/deepgram_api_key";
          model = "nova-3";
          smart_format = true;
          diarize = true;
          punctuate = true;
          filler_words = true;
          numerals = true;
        };
      };
    };
  };
}
