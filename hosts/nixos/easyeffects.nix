{ pkgs, ... }:
{
  services.easyeffects = {
    enable = true;
    package = pkgs.unstable.easyeffects;
    preset = "sennheiser-hd600";
    extraPresets = {
      "sennheiser-hd600" = {
        output = {
          blocklist = [ ];
          plugins_order = [ "equalizer#0" ];
          "equalizer#0" = {
            bypass = false;
            "input-gain" = -10.91;
            "output-gain" = 0.0;
            mode = "IIR";
            "num-bands" = 10;
            "split-channels" = false;

            # Filter 1: LSC 105 Hz +13.7 dB Q 0.70
            "band0-frequency" = 105.0;
            "band0-gain" = 13.7;
            "band0-mode" = "APO (DR)";
            "band0-mute" = false;
            "band0-q" = 0.70;
            "band0-slope" = "x1";
            "band0-solo" = false;
            "band0-type" = "Lo-shelf";

            # Filter 2: PK 63.1 Hz -7.7 dB Q 0.48
            "band1-frequency" = 63.1;
            "band1-gain" = -7.7;
            "band1-mode" = "APO (DR)";
            "band1-mute" = false;
            "band1-q" = 0.48;
            "band1-slope" = "x1";
            "band1-solo" = false;
            "band1-type" = "Bell";

            # Filter 3: PK 632.8 Hz +0.6 dB Q 1.03
            "band2-frequency" = 632.8;
            "band2-gain" = 0.6;
            "band2-mode" = "APO (DR)";
            "band2-mute" = false;
            "band2-q" = 1.03;
            "band2-slope" = "x1";
            "band2-solo" = false;
            "band2-type" = "Bell";

            # Filter 4: PK 1177.4 Hz -1.3 dB Q 2.51
            "band3-frequency" = 1177.4;
            "band3-gain" = -1.3;
            "band3-mode" = "APO (DR)";
            "band3-mute" = false;
            "band3-q" = 2.51;
            "band3-slope" = "x1";
            "band3-solo" = false;
            "band3-type" = "Bell";

            # Filter 5: PK 3482.0 Hz -1.6 dB Q 3.55
            "band4-frequency" = 3482.0;
            "band4-gain" = -1.6;
            "band4-mode" = "APO (DR)";
            "band4-mute" = false;
            "band4-q" = 3.55;
            "band4-slope" = "x1";
            "band4-solo" = false;
            "band4-type" = "Bell";

            # Filter 6: PK 4222.0 Hz +2.0 dB Q 5.89
            "band5-frequency" = 4222.0;
            "band5-gain" = 2.0;
            "band5-mode" = "APO (DR)";
            "band5-mute" = false;
            "band5-q" = 5.89;
            "band5-slope" = "x1";
            "band5-solo" = false;
            "band5-type" = "Bell";

            # Filter 7: PK 4964.3 Hz -1.2 dB Q 5.50
            "band6-frequency" = 4964.3;
            "band6-gain" = -1.2;
            "band6-mode" = "APO (DR)";
            "band6-mute" = false;
            "band6-q" = 5.50;
            "band6-slope" = "x1";
            "band6-solo" = false;
            "band6-type" = "Bell";

            # Filter 8: PK 6917.2 Hz +2.5 dB Q 5.40
            "band7-frequency" = 6917.2;
            "band7-gain" = 2.5;
            "band7-mode" = "APO (DR)";
            "band7-mute" = false;
            "band7-q" = 5.40;
            "band7-slope" = "x1";
            "band7-solo" = false;
            "band7-type" = "Bell";

            # Filter 9: PK 9265.6 Hz +4.6 dB Q 2.02
            "band8-frequency" = 9265.6;
            "band8-gain" = 4.6;
            "band8-mode" = "APO (DR)";
            "band8-mute" = false;
            "band8-q" = 2.02;
            "band8-slope" = "x1";
            "band8-solo" = false;
            "band8-type" = "Bell";

            # Filter 10: HSC 10000.0 Hz -3.8 dB Q 0.70
            "band9-frequency" = 10000.0;
            "band9-gain" = -3.8;
            "band9-mode" = "APO (DR)";
            "band9-mute" = false;
            "band9-q" = 0.70;
            "band9-slope" = "x1";
            "band9-solo" = false;
            "band9-type" = "Hi-shelf";
          };
        };
      };
    };
  };
}
