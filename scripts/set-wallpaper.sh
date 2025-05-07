#!/usr/bin/env bash

# Parse command line arguments
WALLPAPER_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: ${0##*/} [OPTIONS] WALLPAPER_DIR"
            echo "Options:"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "WALLPAPER_DIR is required and should be the directory containing wallpaper images"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
        *)
            if [ -z "$WALLPAPER_DIR" ]; then
                WALLPAPER_DIR="$1"
            else
                echo "Error: Unexpected argument: $1"
                echo "Use -h or --help for usage information"
                exit 1
            fi
            ;;
    esac
    shift
done

# Check if wallpaper directory was provided
if [ -z "$WALLPAPER_DIR" ]; then
    echo "Error: WALLPAPER_DIR is required"
    echo "Use -h or --help for usage information"
    exit 1
fi

# Exit on error
set -e

# Check for tools
[ ${BASH_VERSINFO[0]} -lt 4 ] && { echo "ERROR: bash version 4 or higher is required." >&2; exit 2; }
xrandr --help &>/dev/null || { echo "ERROR: Missing xrandr. Install xserver utils." >&2; exit 2; }
tail --version &>/dev/null || { echo "ERROR: Missing tail. Install coreutils." >&2; exit 2; }
convert -version &>/dev/null || { echo "ERROR: Missing convert. Install imagemagick." >&2; exit 2; }
bc --version &>/dev/null || { echo "ERROR: Missing bc. Install bc." >&2; exit 2; }
jq --version &>/dev/null || { echo "ERROR: Missing jq. Install jq." >&2; exit 2; }

# Function to set KDE wallpaper for a specific screen
set_kde_wallpaper() {
    local image_path="$1"
    local screen_number="$2"
    dbus-send --session --dest=org.kde.plasmashell --type=method_call /PlasmaShell org.kde.PlasmaShell.evaluateScript "string:
    var Desktops = desktops();
    for (i=0;i<Desktops.length;i++) {
        d = Desktops[i];
        if (d.screen == $screen_number) {
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper',
                                        'org.kde.image',
                                        'General');
            d.writeConfig('Image', 'file://${image_path}');
            d.reloadConfig();
        }
    }"
}

# Get random image from wallpaper directory
RANDOM_IMAGE=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

if [ -z "$RANDOM_IMAGE" ]; then
    echo "No images found in $WALLPAPER_DIR"
    exit 1
fi

echo "Selected wallpaper: $RANDOM_IMAGE"

# Check input file
[ -r "${RANDOM_IMAGE}" ] && convert "${RANDOM_IMAGE}" info: &>/dev/null || { echo "ERROR: Supplied argument '${RANDOM_IMAGE}' was not found or is in unknown image format."; exit 3; }

# Get image dimensions
IMAGE_INFO=$(identify -format "%w %h" "$RANDOM_IMAGE")
IMAGE_WIDTH=${IMAGE_INFO% *}
IMAGE_HEIGHT=${IMAGE_INFO#* }
IMAGE_RATIO=$(echo "scale=4; $IMAGE_WIDTH / $IMAGE_HEIGHT" | bc)

declare -a NAME WIDTH HEIGHT OFFSETX OFFSETY MONITOR_ID
declare MINX=65535 MINY=65535 MAXX=0 MAXY=0

# First, get the monitor IDs and their order
while read ID N1 RES N; do
    ID=$(( ${ID%:} ))
    MONITOR_ID[$ID]="$N"
done <<<"$(xrandr --listactivemonitors|tail -n +2)"

# Now get the geometry information
while read ID N1 RES N; do
    W=$(( ${RES%%/*} ))
    H="${RES#*x}"
    H=$(( ${H%%/*} ))
    X="${RES#*+}"
    Y=$(( ${X#*+} ))
    X=$(( ${X%%+*} ))
    ID=$(( ${ID%:} ))

    NAME[${ID}]="${N//[^A-Za-z0-9-]/_}"
    WIDTH[${ID}]="${W}"
    HEIGHT[${ID}]="${H}"
    OFFSETX[${ID}]="${X}"
    OFFSETY[${ID}]="${Y}"

    [ ${MINX} -gt ${X} ] && MINX=${X}
    [ ${MINY} -gt ${Y} ] && MINY=${Y}
    [ ${MAXX} -lt $(( X+W )) ] && MAXX=$(( X+W ))
    [ ${MAXY} -lt $(( Y+H )) ] && MAXY=$(( Y+H ))
done <<<"$(xrandr --listactivemonitors|tail -n +2)"

# Calculate total display area
TOTAL_WIDTH=$((MAXX-MINX))
TOTAL_HEIGHT=$((MAXY-MINY))
TOTAL_RATIO=$(echo "scale=4; $TOTAL_WIDTH / $TOTAL_HEIGHT" | bc)

# Create a directory in /tmp for this session's wallpapers
TEMP_DIR="/tmp/wallpapers-$$"
mkdir -p "$TEMP_DIR"

# Parse monitor mapping from environment variable
declare -A MONITOR_MAP
if [ -n "$MONITOR_MAPPING" ]; then
    while IFS="=" read -r monitor screen; do
        # Remove quotes and clean up the key
        monitor=$(echo "$monitor" | tr -d '"' | tr -d ',')
        screen=$(echo "$screen" | tr -d '"' | tr -d ',')
        MONITOR_MAP["$monitor"]=$screen
    done < <(echo "$MONITOR_MAPPING" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"')
fi

# Split and set wallpapers
for I in ${!NAME[@]}; do
    OUTPUT="$TEMP_DIR/${RANDOM_IMAGE##*/}_${I}_${NAME[$I]}.${RANDOM_IMAGE##*.}"
    
    # Calculate the crop region maintaining aspect ratio
    if (( $(echo "$IMAGE_RATIO > $TOTAL_RATIO" | bc -l) )); then
        # Image is wider than display area
        CROP_WIDTH=$(echo "scale=0; $IMAGE_HEIGHT * $TOTAL_RATIO / 1" | bc)
        CROP_HEIGHT=$IMAGE_HEIGHT
        CROP_X=$(echo "scale=0; ($IMAGE_WIDTH - $CROP_WIDTH) / 2 / 1" | bc)
        CROP_Y=0
    else
        # Image is taller than display area
        CROP_WIDTH=$IMAGE_WIDTH
        CROP_HEIGHT=$(echo "scale=0; $IMAGE_WIDTH / $TOTAL_RATIO / 1" | bc)
        CROP_X=0
        CROP_Y=$(echo "scale=0; ($IMAGE_HEIGHT - $CROP_HEIGHT) / 2 / 1" | bc)
    fi

    # Calculate the portion of the image that corresponds to this monitor
    MONITOR_X_RATIO=$(echo "scale=4; (${OFFSETX[$I]} - $MINX) / $TOTAL_WIDTH" | bc)
    MONITOR_Y_RATIO=$(echo "scale=4; (${OFFSETY[$I]} - $MINY) / $TOTAL_HEIGHT" | bc)
    MONITOR_WIDTH_RATIO=$(echo "scale=4; ${WIDTH[$I]} / $TOTAL_WIDTH" | bc)
    MONITOR_HEIGHT_RATIO=$(echo "scale=4; ${HEIGHT[$I]} / $TOTAL_HEIGHT" | bc)

    # Calculate the actual crop coordinates for this monitor
    CROP_START_X=$(echo "scale=0; ($CROP_X + $CROP_WIDTH * $MONITOR_X_RATIO) / 1" | bc)
    CROP_START_Y=$(echo "scale=0; ($CROP_Y + $CROP_HEIGHT * $MONITOR_Y_RATIO) / 1" | bc)
    CROP_END_X=$(echo "scale=0; ($CROP_START_X + $CROP_WIDTH * $MONITOR_WIDTH_RATIO) / 1" | bc)
    CROP_END_Y=$(echo "scale=0; ($CROP_START_Y + $CROP_HEIGHT * $MONITOR_HEIGHT_RATIO) / 1" | bc)
    CROP_WIDTH=$((CROP_END_X - CROP_START_X))
    CROP_HEIGHT=$((CROP_END_Y - CROP_START_Y))

    # Get the screen number from the mapping, or use the index if not mapped
    SCREEN_NUMBER=${MONITOR_MAP[${MONITOR_ID[$I]}]:-$I}
    
    echo "Setting wallpaper for monitor ${MONITOR_ID[$I]} (screen $SCREEN_NUMBER)"
    echo "Crop region: ${CROP_WIDTH}x${CROP_HEIGHT}+${CROP_START_X}+${CROP_START_Y}"
    
    # Crop and resize the image
    magick "${RANDOM_IMAGE}" -crop "${CROP_WIDTH}x${CROP_HEIGHT}+${CROP_START_X}+${CROP_START_Y}" -resize "${WIDTH[$I]}x${HEIGHT[$I]}" "$OUTPUT"
    set_kde_wallpaper "$OUTPUT" "$SCREEN_NUMBER"
done