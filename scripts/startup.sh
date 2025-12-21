#!/bin/bash

# Run picom in background
picom -b

# Run the script to toggle monitor grayscale
~/grayscale.sh

# Swap left Alt and Super keys
setxkbmap -option 'altwin:swap_lalt_lwin'
