#!/bin/bash
set -euo pipefail

echo ">>> FLATPAK_START <<<"
echo "--- Configuring Flatpak ---"

if command -v snap &>/dev/null && snap list | grep -q "^flatpak "; then
	sudo snap remove flatpak
fi

sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

if ! flatpak list | grep -q "md.obsidian.Obsidian"; then
	echo "Installing Obsidian..."
	flatpak install flathub md.obsidian.Obsidian -y
fi

flatpak_exports="$HOME/.local/share/flatpak/exports/share"
if [[ ":$XDG_DATA_DIRS:" != *":$flatpak_exports:"* ]]; then
	export XDG_DATA_DIRS="$flatpak_exports:$XDG_DATA_DIRS"
fi

echo ">>> FLATPAK_COMPLETE <<<"
