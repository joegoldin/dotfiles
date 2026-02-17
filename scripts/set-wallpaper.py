#!/usr/bin/env python3
"""
KDE Plasma Multi-Monitor Wallpaper Spanner

Takes a random image from multiple folders and properly spans it across all monitors,
creating separate slices for each monitor to create one seamless wallpaper.
"""

import os
import sys
import random
import subprocess
from PIL import Image
import time

# Supported image extensions
SUPPORTED_IMAGE_EXTENSIONS = (".jpg", ".jpeg", ".png", ".bmp", ".gif", ".tiff", ".webp")
TEMP_DIR = "/tmp/wallpaper_spans"  # Temporary directory for sliced images
TIMESTAMP = int(time.time())  # Current timestamp for unique filenames
DBUS_TIMEOUT = 15  # Seconds to wait for DBus calls before giving up

random.seed(TIMESTAMP)


def ensure_temp_dir():
    """Ensure temporary directory exists"""
    if not os.path.exists(TEMP_DIR):
        os.makedirs(TEMP_DIR)
    else:
        # Clean up old files
        for f in os.listdir(TEMP_DIR):
            try:
                os.remove(os.path.join(TEMP_DIR, f))
            except OSError:
                pass


def find_random_image(folder_paths):
    """Find a random image from the specified folders and their subfolders"""
    if not isinstance(folder_paths, list):
        folder_paths = [folder_paths]

    # Get all files in directories and subdirectories with supported image extensions
    image_files = []
    for folder_path in folder_paths:
        print(f"Searching for images in {folder_path}")
        if not os.path.isdir(folder_path):
            print(f"Warning: '{folder_path}' is not a valid directory, skipping")
            continue

        for root, _, files in os.walk(folder_path):
            print(f"Found {len(files)} files in {root}")
            for f in files:
                if f.lower().endswith(SUPPORTED_IMAGE_EXTENSIONS):
                    image_files.append(os.path.join(root, f))

    if not image_files:
        print(
            "Error: No supported image files found in any of the provided directories"
        )
        sys.exit(1)

    # Select a random image
    return random.choice(image_files)


def get_monitor_info():
    """Get monitor information using xrandr command"""
    monitors = []

    try:
        # Run xrandr to get monitor information
        output = subprocess.check_output(["xrandr", "--current"]).decode("utf-8")

        # Parse the output to extract monitor information
        for line in output.split("\n"):
            # Lines with 'connected' describe monitors
            if " connected " in line:
                parts = line.split()
                name = parts[0]

                # Find width, height, and position
                geometry = None
                for part in parts:
                    if "x" in part and "+" in part:
                        geometry = part
                        break

                if geometry:
                    dimensions, rest = geometry.split("+", 1)
                    width, height = map(int, dimensions.split("x"))
                    x_pos, y_pos = map(int, rest.split("+"))

                    print(
                        f"Found monitor: {name}, "
                        f"size: {width}x{height}, "
                        f"position: {x_pos}+{y_pos}"
                    )
                    monitors.append(
                        {
                            "name": name,
                            "width": width,
                            "height": height,
                            "x": x_pos,
                            "y": y_pos,
                        }
                    )

        # Sort monitors by position (left to right, top to bottom)
        monitors.sort(key=lambda m: (m["x"], m["y"]))
        return monitors
    except Exception as e:
        print(f"Error getting monitor information: {e}")
        sys.exit(1)


def compute_canvas_size(monitors):
    """Compute the total canvas size based on monitor positions and sizes"""
    if not monitors:
        print("Error: No monitors detected")
        sys.exit(1)

    # Find the rightmost and bottommost points
    right_edge = max(m["x"] + m["width"] for m in monitors)
    bottom_edge = max(m["y"] + m["height"] for m in monitors)

    return (right_edge, bottom_edge)


def resize_image_to_fill(img, canvas_size):
    """Resize image to fill the canvas while maintaining aspect ratio"""
    # Get original dimensions
    img_width, img_height = img.size
    canvas_width, canvas_height = canvas_size

    # Calculate aspect ratios
    img_ratio = img_width / img_height
    canvas_ratio = canvas_width / canvas_height

    # Resize to fill the canvas
    if img_ratio > canvas_ratio:
        # Image is wider than canvas (relative to height)
        print("Image is wider than canvas (relative to height)")
        new_height = canvas_height
        new_width = int(new_height * img_ratio)
    else:
        # Image is taller than canvas (relative to width)
        print("Image is taller than canvas (relative to width)")
        new_width = canvas_width
        new_height = int(new_width / img_ratio)

    # Resize the image
    resized_img = img.resize((new_width, new_height), Image.LANCZOS)

    # Center crop to match canvas size
    left = (new_width - canvas_width) // 2
    top = (new_height - canvas_height) // 2
    right = left + canvas_width
    bottom = top + canvas_height

    # Ensure we don't go out of bounds
    left = max(0, left)
    top = max(0, top)
    right = min(new_width, right)
    bottom = min(new_height, bottom)

    return resized_img.crop((left, top, right, bottom))


def slice_image_for_monitors(img, monitors):
    """Slice the main image for each monitor"""
    slices = []

    for idx, monitor in enumerate(monitors):
        print(f"Slicing image for monitor {idx}")
        # Crop the relevant portion for this monitor
        left = monitor["x"]
        top = monitor["y"]
        right = left + monitor["width"]
        bottom = top + monitor["height"]

        # Create cropped image for this monitor
        slice_img = img.crop((left, top, right, bottom))

        # Save to temporary file with timestamp
        slice_path = os.path.join(TEMP_DIR, f"slice_{TIMESTAMP}_{idx}.png")
        slice_img.save(slice_path)
        print(f"Saved slice to {slice_path}")

        slices.append({"path": slice_path, "monitor": monitor})

    return slices


def set_kde_wallpaper(slices):
    """Set each slice as wallpaper for its corresponding monitor in KDE Plasma"""
    import dbus

    # KDE Plasma JavaScript to set wallpapers
    script = """
var desktopArray = [];
for (var desktopIndex in desktops()) {{
    var desktop = desktops()[desktopIndex];
    if (desktop.screen != -1) {{
        desktopArray.push(desktop);
    }}
}}

// Sort by vertical then horizontal position
desktopArray.sort(function(a, b) {{
    var ga = screenGeometry(a.screen);
    var gb = screenGeometry(b.screen);
    if (ga.left !== gb.left) return ga.left - gb.left;
    return ga.top - gb.top;
}});

var imageFileArray = Array({0});

for (var k = 0; k < desktopArray.length; k++) {{
    var desktop = desktopArray[k];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
    desktop.writeConfig("Image", imageFileArray[k]);
}}
"""

    # Create list of file:// URLs for the script
    file_urls = [f"file://{s['path']}" for s in slices]
    file_list_str = ", ".join('"' + item + '"' for item in file_urls)

    session_bus = dbus.SessionBus()
    plasma = session_bus.get_object("org.kde.plasmashell", "/PlasmaShell")
    interface = dbus.Interface(plasma, "org.kde.PlasmaShell")

    # Use a timeout so we don't hang forever if plasmashell is unresponsive
    interface.evaluateScript(script.format(file_list_str), timeout=DBUS_TIMEOUT)

    print(f"Set wallpaper slices across {len(slices)} monitors")


def main():
    """Main function to set a random wallpaper spanned across monitors"""
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <folder_path1> [folder_path2 ...]")
        sys.exit(1)

    folder_paths = sys.argv[1:]

    # Ensure our temporary directory exists
    print("Ensuring temp directory exists")
    ensure_temp_dir()

    # Get a random image from all directories
    image_path = find_random_image(folder_paths)
    print(f"Selected image: {image_path}")

    # Get monitor information
    monitors = get_monitor_info()
    print(f"Detected {len(monitors)} monitors")

    # Calculate canvas size
    canvas_size = compute_canvas_size(monitors)
    print(f"Total canvas size: {canvas_size[0]}x{canvas_size[1]}")

    # Open and resize the image
    try:
        original_img = Image.open(image_path)
        resized_img = resize_image_to_fill(original_img, canvas_size)
        print("Resized image")
    except Exception as e:
        print(f"Error processing image: {e}")
        sys.exit(1)

    # Slice the image for each monitor
    slices = slice_image_for_monitors(resized_img, monitors)
    print("Sliced image")
    # Set the wallpaper
    set_kde_wallpaper(slices)
    print("Set wallpaper")


if __name__ == "__main__":
    main()
