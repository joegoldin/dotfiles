# audiomemo (recording + transcription CLI): hm module + shared settings.
# Host-specific device settings live in each host's home.nix; home-manager
# deep-merges them with these.
{ inputs, ... }:
{
  den.aspects.audiomemo.homeManager = {
    imports = [ inputs.audiomemo.homeManagerModules.default ];

    programs.audiomemo = {
      enable = true;
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
  };
}
