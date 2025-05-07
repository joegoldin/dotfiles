{ config, lib, pkgs, username, ... }:

with lib;

let
  cfg = config.services.wallpaper;
  wallpaperScript = pkgs.writeScriptBin "set-wallpaper" ''
    #!${pkgs.bash}/bin/bash
    WALLPAPER_DIR="${cfg.wallpaperDir}"
    SCRIPT_PATH="${config.users.users.${username}.home}/dotfiles/scripts/set-wallpaper.sh"
    MONITOR_MAPPING='${builtins.toJSON cfg.monitorMapping}'
    
    # Get a random image from the wallpaper directory
    RANDOM_IMAGE=$(find "$WALLPAPER_DIR" -maxdepth 999 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)
    
    if [ -n "$RANDOM_IMAGE" ]; then
      MONITOR_MAPPING="$MONITOR_MAPPING" "$SCRIPT_PATH" "$RANDOM_IMAGE"
    else
      echo "No images found in $WALLPAPER_DIR"
      exit 1
    fi
  '';
in {
  options.services.wallpaper = {
    enable = mkEnableOption "wallpaper service";
    wallpaperDir = mkOption {
      type = types.path;
      description = "Directory containing wallpaper images";
    };
    monitorMapping = mkOption {
      type = types.attrsOf types.int;
      description = "Mapping of monitor names to screen numbers";
      default = {};
    };
  };

  config = mkIf cfg.enable {
    services.cron = {
      enable = true;
      systemCronJobs = [
        "0 * * * * ${config.users.users.${username}.home}/.nix-profile/bin/set-wallpaper"
      ];
    };
  };
} 