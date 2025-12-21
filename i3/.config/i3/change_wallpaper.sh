#!/bin/bash

WALLPAPER_DIR="$HOME/possessions/Pictures/desktop-wallpapers/"

# Get a random image from the directory
# This finds all files in the directory, pipes them to shuf (shuffle),
# and takes the first one.
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)

if [ -n "$RANDOM_WALLPAPER" ]; then
	feh --bg-scale "$RANDOM_WALLPAPER"
	# Optional: You might want to save the last set wallpaper path if you
	# want to avoid repeats in a short cycle, but for random, this is fine.
else
	echo "No wallpapers found in $WALLPAPER_DIR"
	dunstify "Wallpaper Error" "No wallpapers found in $WALLPAPER_DIR"
fi
