#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> [DEBUG] SCRIPT STARTED <<<"

# Ask for sudo upfront and keep it alive
sudo -v
echo ">>> [DEBUG] SUDO -V PASSED <<<"
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

echo "Installing base requirements..."

# 0. Cleanup broken LLVM configs from previous runs
echo "Cleaning up potential repository conflicts..."
sudo rm -f /etc/apt/sources.list.d/llvm-18.list*
sudo rm -f /etc/apt/trusted.gpg.d/llvm-18.gpg

# 1. Update package lists (essential for a fresh install)
sudo apt update -y

# 2. Define your "Seed" packages
# Using 'git', 'stow', 'curl', and 'build-essential' (common for building tools)
PACKAGES=(git stow curl build-essential)

# 3. Install only what is missing
for pkg in "${PACKAGES[@]}"; do
	if dpkg -s "$pkg" >/dev/null 2>&1; then
		echo "  [OK] $pkg is already installed."
	else
		echo "  [..] Installing $pkg..."
		sudo apt install -y "$pkg"
	fi
done

# 4. Run Modular Installers
# Get the directory where the script is located to handle relative paths correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">>> BOOTSTRAP_MODULAR_START <<<"
echo "Starting modular installations..."

# Add LLVM repository for clang-18
# Fix: Using 'jammy' instead of 'bookworm' for Ubuntu 22.04
# Fix: Using /usr/share/keyrings/ and [signed-by=...] for modern apt
echo "Configuring LLVM 18 repository..."
curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/llvm-18.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/llvm-18.gpg] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-18 main" | sudo tee /etc/apt/sources.list.d/llvm-18.list
sudo apt update -y

sudo groupadd --system uinput || true
sudo usermod -aG input $USER
sudo usermod -aG uinput $USER
# Add udev rule for non-root access
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-input.rules

# Ensure the install scripts are executable
chmod +x "$SCRIPT_DIR/languages.sh"
chmod +x "$SCRIPT_DIR/packages.sh"

# Execute them
"$SCRIPT_DIR/languages.sh"
"$SCRIPT_DIR/packages.sh"

# --- 5. The Stow Phase ---
echo ">>> BOOTSTRAP_STOW_START <<<"
echo "Linking configurations with Stow..."

# Find the configs directory relative to the script
CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"

# Change directory to the configs folder
cd "$CONFIG_DIR"

for folder in */; do
	folder=${folder%/}
	if [ -d "$folder/.config" ]; then
		TARGET="$HOME/.config/$folder"
	else
		# For things like bash, it's usually ~/.bashrc, but stow handles the dot
		TARGET="$HOME/.$folder"
	fi

	if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
		CURRENT_LINK=$(readlink -f "$TARGET" 2>/dev/null || echo "")
		if [[ $CURRENT_LINK != *"/github/scripts/"* ]]; then
			echo "  [CLEANUP] Removing conflicting target: $TARGET"
			rm -rf "$TARGET"
		fi
	fi

	# 3. Now Stow should have a perfectly empty path to link into
	echo "  [LINK] Stowing $folder..."
	stow -R -t "$HOME" "$folder"
done
echo ">>> BOOTSTRAP_STOW_END <<<"

FONT_NAME="JetBrainsMono"
FONT_DIR="$HOME/.local/share/fonts"
CHECK_FILE="$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf"
VERSION="v3.4.0"

echo ">>> BOOTSTRAP_FONTS_START <<<"
if [ ! -f "$CHECK_FILE" ]; then
	echo "--- Installing $FONT_NAME Nerd Font ---"

	mkdir -p "$FONT_DIR"
	TEMP_DIR=$(mktemp -d)

	# Download only the specific font zip
	curl -L "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${FONT_NAME}.zip" -o "$TEMP_DIR/$FONT_NAME.zip"

	# Unzip into the local fonts directory
	unzip -o "$TEMP_DIR/$FONT_NAME.zip" -d "$FONT_DIR"

	# Cleanup
	rm -rf "$TEMP_DIR"

	# Refresh font cache
	echo "Refreshing font cache..."
	fc-cache -f
else
	echo "--- $FONT_NAME Nerd Font already exists, skipping ---"
fi

EMOJI_CHECK="/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"
if [ ! -f "$EMOJI_CHECK" ]; then
	echo "--- Installing Noto Color Emoji ---"
	sudo apt install -y fonts-noto-color-emoji
	# Refresh font cache
	echo "Refreshing font cache..."
	fc-cache -f
else
	echo "--- Noto Color Emoji already exists, skipping ---"
fi
echo ">>> BOOTSTRAP_FONTS_END <<<"

echo ">>> BOOTSTRAP_COMPLETE <<<"
echo "Setup complete! Restart your shell."
