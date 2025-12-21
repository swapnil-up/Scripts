#!/bin/bash

# Define the path to your i3 config file
I3_CONFIG="$HOME/.config/i3/config"

# Check if the title bar is currently hidden (by checking for the font size 0 setting)
if grep -q "font pango:DejaVu Sans Mono 0" "$I3_CONFIG"; then
	# Title bar is hidden, so we want to show it
	sed -i '/font pango:DejaVu Sans Mono 0/d' "$I3_CONFIG"  # Remove the font setting
	sed -i '/title_format "<span alpha="0">/d' "$I3_CONFIG" # Remove the title format line
	i3-msg reload                                           # Reload i3 configuration
	notify-send "Title Bar" "Title bar is now visible."
else
	# Title bar is visible, so we want to hide it
	echo 'font pango:DejaVu Sans Mono 0' >>"$I3_CONFIG"
	echo 'for_window [class=".*"] title_format "<span alpha="0">%title</span>"' >>"$I3_CONFIG"
	i3-msg reload # Reload i3 configuration
	notify-send "Title Bar" "Title bar is now hidden."
fi
