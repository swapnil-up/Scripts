#!/bin/bash
set -euo pipefail

echo ">>> FONTS_START <<<"
echo "--- Installing Fonts ---"

FONT_NAME="JetBrainsMono"
FONT_DIR="$HOME/.local/share/fonts"
CHECK_FILE="$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf"
VERSION="v3.4.0"

if [ ! -f "$CHECK_FILE" ]; then
	echo "Installing $FONT_NAME Nerd Font..."
	mkdir -p "$FONT_DIR"
	TEMP_DIR=$(mktemp -d)
	curl -L "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${FONT_NAME}.zip" -o "$TEMP_DIR/$FONT_NAME.zip"
	unzip -o "$TEMP_DIR/$FONT_NAME.zip" -d "$FONT_DIR"
	rm -rf "$TEMP_DIR"
	fc-cache -f
fi

EMOJI_CHECK="/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"
if [ ! -f "$EMOJI_CHECK" ]; then
	echo "Installing Noto Color Emoji..."
	sudo apt install -y fonts-noto-color-emoji
	fc-cache -f
fi

echo ">>> FONTS_COMPLETE <<<"
