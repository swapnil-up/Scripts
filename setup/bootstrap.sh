#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Ask for sudo upfront and keep it alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "Installing base requirements..."

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

echo "Starting modular installations..."

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
        if [[ "$CURRENT_LINK" != *"/github/scripts/"* ]]; then
            echo "  [CLEANUP] Removing conflicting target: $TARGET"
            rm -rf "$TARGET"
        fi
    fi

    # 3. Now Stow should have a perfectly empty path to link into
    echo "  [LINK] Stowing $folder..."
    stow -R -t "$HOME" "$folder"
done


FONT_NAME="JetBrainsMono" # Change this to your preference
FONT_DIR="$HOME/.local/share/fonts"
VERSION="v3.4.0"

if ! fc-list | grep -qi "$FONT_NAME"; then
    echo "--- Installing $FONT_NAME Nerd Font ---"
    
    mkdir -p "$FONT_DIR"
    TEMP_DIR=$(mktemp -d)
    
    # Download only the specific font zip
    curl -L "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${FONT_NAME}.zip" -o "$TEMP_DIR/$FONT_NAME.zip"
    
    # Unzip into the local fonts directory
    unzip "$TEMP_DIR/$FONT_NAME.zip" -d "$FONT_DIR"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    # Refresh font cache
    echo "Refreshing font cache..."
    fc-cache -f
else
    echo "--- $FONT_NAME Nerd Font already exists, skipping ---"
fi

echo "Setup complete! Restart your shell."
